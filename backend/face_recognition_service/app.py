from flask import Flask, request, jsonify
from flask_cors import CORS
import dlib  # Use the binary version we installed
import numpy as np
import cv2
import base64
import os
import json
from PIL import Image
from io import BytesIO


app = Flask(__name__)
CORS(app)

# Directory for storing face data
os.makedirs('faces', exist_ok=True)
DATABASE_FILE = 'faces/faces_db.json'

# Initialize database file if not exists
if not os.path.exists(DATABASE_FILE):
    with open(DATABASE_FILE, 'w') as f:
        json.dump([], f)

# Model file paths
SHAPE_PREDICTOR_PATH = "shape_predictor_68_face_landmarks.dat"
FACE_RECOGNITION_MODEL_PATH = "dlib_face_recognition_resnet_model_v1.dat"

# Load face detection and recognition models
detector = dlib.get_frontal_face_detector()

def download_models():
    """Download required model files if they don't exist"""
    try:
        # Download shape predictor if needed
        if not os.path.exists(SHAPE_PREDICTOR_PATH):
            print("Downloading shape predictor model...")
            import urllib.request
            urllib.request.urlretrieve(
                "https://github.com/davisking/dlib-models/raw/master/shape_predictor_68_face_landmarks.dat.bz2",
                "shape_predictor_68_face_landmarks.dat.bz2"
            )
            print("Extracting shape predictor model...")
            import bz2
            with open(SHAPE_PREDICTOR_PATH, 'wb') as new_file, \
                bz2.BZ2File("shape_predictor_68_face_landmarks.dat.bz2", 'rb') as file:
                for data in iter(lambda: file.read(100 * 1024), b''):
                    new_file.write(data)
            print("Shape predictor model downloaded and extracted")
            
        # Download face recognition model if needed
        if not os.path.exists(FACE_RECOGNITION_MODEL_PATH):
            print("Downloading face recognition model...")
            import urllib.request
            urllib.request.urlretrieve(
                "https://github.com/davisking/dlib-models/raw/master/dlib_face_recognition_resnet_model_v1.dat.bz2",
                "dlib_face_recognition_resnet_model_v1.dat.bz2"
            )
            print("Extracting face recognition model...")
            import bz2
            with open(FACE_RECOGNITION_MODEL_PATH, 'wb') as new_file, \
                bz2.BZ2File("dlib_face_recognition_resnet_model_v1.dat.bz2", 'rb') as file:
                for data in iter(lambda: file.read(100 * 1024), b''):
                    new_file.write(data)
            print("Face recognition model downloaded and extracted")
    except Exception as e:
        print(f"Error downloading models: {e}")
        return False
    return True

def load_faces_db():
    with open(DATABASE_FILE, 'r') as f:
        return json.load(f)

def save_faces_db(db):
    with open(DATABASE_FILE, 'w') as f:
        json.dump(db, f)

@app.route('/recognize', methods=['POST'])
def recognize_face():
    print("Received recognition request")
    
    if not request.json:
        print("Error: No JSON data in request")
        return jsonify({'status': 'error', 'message': 'No JSON data provided'}), 400
        
    if 'image' not in request.json:
        print("Error: No image field in JSON data")
        return jsonify({'status': 'error', 'message': 'No image provided'}), 400

    # Get the base64 encoded image and convert to numpy array
    encoded_data = request.json['image']
    print(f"Received image data of length: {len(encoded_data)}")
    
    try:
        img_data = base64.b64decode(encoded_data)
        print(f"Decoded base64 data length: {len(img_data)}")
        
        # Convert to image
        image = Image.open(BytesIO(img_data))
        rgb_img = np.array(image)
        print(f"Image shape: {rgb_img.shape}")
        
        # Convert to BGR for OpenCV processing if needed
        if len(rgb_img.shape) == 3 and rgb_img.shape[2] == 4:  # If RGBA
            rgb_img = cv2.cvtColor(rgb_img, cv2.COLOR_RGBA2RGB)
        
        # Enhanced pre-processing to improve face detection
        # Resize if too large
        if rgb_img.shape[0] > 800 or rgb_img.shape[1] > 800:
            scale = 800 / max(rgb_img.shape[0], rgb_img.shape[1])
            rgb_img = cv2.resize(rgb_img, None, fx=scale, fy=scale)
        
        # Enhance contrast and brightness
        lab = cv2.cvtColor(rgb_img, cv2.COLOR_RGB2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(8, 8))  # Increased from 3.0
        cl = clahe.apply(l)
        enhanced_lab = cv2.merge((cl, a, b))
        rgb_img = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2RGB)
        
        # Additional brightness enhancement
        brightness_img = cv2.convertScaleAbs(rgb_img, alpha=1.2, beta=15)  # Added brightness boost
        
        # First try the original image with dlib
        print("Detecting faces with dlib...")
        face_locations = detector(rgb_img, 0)  # More sensitive mode
        print(f"Found {len(face_locations)} faces")
        
        # If no faces found, try the brightness-enhanced image
        if not face_locations:
            print("Trying brightness-enhanced image...")
            face_locations = detector(brightness_img, 0)
            print(f"Found {len(face_locations)} faces with enhanced brightness")
            if face_locations:
                rgb_img = brightness_img  # Use the enhanced image
            
        # If still no faces, try OpenCV's detector
        if not face_locations:
            print("Trying OpenCV detector as backup...")
            face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
            gray = cv2.cvtColor(brightness_img, cv2.COLOR_RGB2GRAY)
            # Make OpenCV detector more sensitive
            opencv_faces = face_cascade.detectMultiScale(
                gray, 
                scaleFactor=1.05,  # Reduced from 1.1, more sensitive
                minNeighbors=3,    # Reduced from 5, more sensitive
                minSize=(50, 50)   # Minimum face size to detect
            )
            
            if len(opencv_faces) > 0:
                # Convert OpenCV face format to dlib format
                for (x, y, w, h) in opencv_faces:
                    face_locations.append(dlib.rectangle(x, y, x+w, y+h))
                print(f"OpenCV detected {len(opencv_faces)} faces")
                rgb_img = brightness_img  # Use the enhanced image
        
        # Registration mode - if we're called from register route and face detection failed,
        # attempt to use a more lenient approach for registration
        is_registration = request.path == '/register' or not face_locations
        
        if not face_locations and is_registration:
            print("Face detection failed. Using backup method for registration...")
            # For registration, if all else fails, try to assume a face in the center of the image
            h, w = rgb_img.shape[:2]
            center_x, center_y = w // 2, h // 2
            face_size = min(w, h) // 2
            face_locations = [dlib.rectangle(
                center_x - face_size // 2,
                center_y - face_size // 2,
                center_x + face_size // 2,
                center_y + face_size // 2
            )]
            print("Using centered face region as fallback")
        
        if not face_locations:
            # Provide a more helpful error message to help users position their face better
            return jsonify({
                'status': 'error', 
                'message': 'No face detected. Please try again with better lighting, position your face in the center of the frame, and ensure your entire face is visible.'
            }), 400
        
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return jsonify({'status': 'error', 'message': f'Error processing image: {str(e)}'}), 400
    
    # Get the shape predictor
    shape_predictor = dlib.shape_predictor(SHAPE_PREDICTOR_PATH)
    face_recognizer = dlib.face_recognition_model_v1(FACE_RECOGNITION_MODEL_PATH)
    
    face_encodings = []
    for face in face_locations:
        # Get face shape
        shape = shape_predictor(rgb_img, face)
        # Get face encoding
        face_encoding = face_recognizer.compute_face_descriptor(rgb_img, shape)
        face_encodings.append(np.array(face_encoding))
    
    # Load face database
    faces_db = load_faces_db()
    print(f"Loaded {len(faces_db)} faces from database")
    
    # Debug - print database entries
    for i, face in enumerate(faces_db):
        print(f"DB Entry {i}: UserId={face.get('userId', 'unknown')}, Username={face.get('username', 'unknown')}")
    
    for face_encoding in face_encodings:
        best_match = None
        best_distance = 0.5  # Lower from 0.6 to make matching more strict
        
        for face in faces_db:
            if 'encoding' not in face:
                print(f"Warning: Face entry missing encoding: {face}")
                continue
                
            stored_encoding = np.array(face['encoding'])
            # Calculate Euclidean distance
            distance = np.linalg.norm(face_encoding - stored_encoding)
            print(f"Distance to user {face.get('username', 'unknown')} (ID: {face.get('userId', 'unknown')}): {distance}")
            
            if distance < best_distance:
                best_match = face
                best_distance = distance        
        if best_match:
            print(f"Found match: UserId={best_match.get('userId', 'unknown')}, Username={best_match.get('username', 'unknown')}, Distance={best_distance}")
            return jsonify({
                'status': 'success', 
                'recognized': True, 
                'userId': best_match['userId'],
                'username': best_match['username']
            })
    
    # If we get here, no match was found
    print("No face match found. Needs registration.")
    return jsonify({
        'status': 'success', 
        'recognized': False,
        'message': 'Face not recognized'
    })

@app.route('/register', methods=['POST'])
def register_face():
    print("Received face registration request")
    
    if not request.json:
        print("Error: No JSON data in request")
        return jsonify({'status': 'error', 'message': 'No JSON data provided'}), 400
        
    required_fields = ['image', 'userId', 'username']
    for field in required_fields:
        if field not in request.json:
            print(f"Error: Missing required field '{field}'")
            return jsonify({'status': 'error', 'message': f'Missing required field: {field}'}), 400

    # Get user information
    user_id = request.json['userId']
    username = request.json['username']
    print(f"Registering face for userId={user_id}, username={username}")
    
    # Get the base64 encoded image and convert to numpy array
    encoded_data = request.json['image']
    print(f"Received image data of length: {len(encoded_data)}")
    
    try:
        img_data = base64.b64decode(encoded_data)
        print(f"Decoded base64 data length: {len(img_data)}")
        
        # Convert to image
        image = Image.open(BytesIO(img_data))
        rgb_img = np.array(image)
        print(f"Image shape: {rgb_img.shape}")
        
        # Convert to BGR for OpenCV processing if needed
        if len(rgb_img.shape) == 3 and rgb_img.shape[2] == 4:  # If RGBA
            rgb_img = cv2.cvtColor(rgb_img, cv2.COLOR_RGBA2RGB)
        
        # Enhanced pre-processing for registration
        # Resize if too large
        if rgb_img.shape[0] > 800 or rgb_img.shape[1] > 800:
            scale = 800 / max(rgb_img.shape[0], rgb_img.shape[1])
            rgb_img = cv2.resize(rgb_img, None, fx=scale, fy=scale)
            
        # Enhance contrast and brightness for better face detection
        lab = cv2.cvtColor(rgb_img, cv2.COLOR_RGB2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(8, 8))
        cl = clahe.apply(l)
        enhanced_lab = cv2.merge((cl, a, b))
        rgb_img = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2RGB)
        
        # Find faces with multiple methods for better results
        face_locations = detector(rgb_img, 0)
        print(f"Found {len(face_locations)} faces with initial detection")
        
        if not face_locations:
            # Try with brightness enhancement
            brightness_img = cv2.convertScaleAbs(rgb_img, alpha=1.2, beta=15)
            face_locations = detector(brightness_img, 0)
            print(f"Found {len(face_locations)} faces with enhanced brightness")
            
            if face_locations:
                rgb_img = brightness_img  # Use the enhanced image
        
        if not face_locations:
            # Try OpenCV as a backup
            face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
            gray = cv2.cvtColor(rgb_img, cv2.COLOR_RGB2GRAY)
            opencv_faces = face_cascade.detectMultiScale(
                gray, 
                scaleFactor=1.05,
                minNeighbors=3,
                minSize=(50, 50)
            )
            
            if len(opencv_faces) > 0:
                for (x, y, w, h) in opencv_faces:
                    face_locations.append(dlib.rectangle(x, y, x+w, y+h))
                print(f"OpenCV detected {len(opencv_faces)} faces")
        
        if not face_locations:
            # Last resort for registration - assume face is centered
            h, w = rgb_img.shape[:2]
            center_x, center_y = w // 2, h // 2
            face_size = min(w, h) // 2
            face_locations = [dlib.rectangle(
                center_x - face_size // 2,
                center_y - face_size // 2,
                center_x + face_size // 2,
                center_y + face_size // 2
            )]
            print("Using centered face region as fallback")
        
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return jsonify({'status': 'error', 'message': f'Error processing image: {str(e)}'}), 400
    
    # Get the shape predictor
    shape_predictor = dlib.shape_predictor(SHAPE_PREDICTOR_PATH)
    face_recognizer = dlib.face_recognition_model_v1(FACE_RECOGNITION_MODEL_PATH)
    
    try:
        # Get face encoding from the first detected face
        shape = shape_predictor(rgb_img, face_locations[0])
        face_encoding = face_recognizer.compute_face_descriptor(rgb_img, shape)
        
        # Convert to a regular Python list for JSON serialization
        face_encoding_list = list(face_encoding)
        
        # Load face database
        faces_db = load_faces_db()
        user_id = request.json['userId']
        
        # Explicitly convert string IDs to strings for consistent comparison
        user_id_str = str(user_id)
        
        print(f"Looking for existing face for user ID: {user_id_str}")
        
        # Remove any existing face data for this user to avoid duplicates
        faces_db = [face for face in faces_db if str(face.get('userId', '')) != user_id_str]
        print(f"After filtering, database contains {len(faces_db)} faces")
        
        # Create new face data with string ID to ensure consistent comparison
        face_data = {
            'userId': user_id_str,
            'username': username,
            'encoding': face_encoding_list
        }
        
        # Add the new face data
        faces_db.append(face_data)
        
        # Save to file
        try:
            save_faces_db(faces_db)
            print(f"Successfully saved face for user ID: {user_id_str}")
            
            # Verify the file was updated
            with open(DATABASE_FILE, 'r') as f:
                saved_data = json.load(f)
                print(f"Verified database file contains {len(saved_data)} entries")
                
        except Exception as e:
            print(f"Error saving face database: {str(e)}")
            return jsonify({'status': 'error', 'message': f'Error saving face database: {str(e)}'}), 500
        
        return jsonify({
            'status': 'success', 
            'message': 'Face registered successfully',
            'userId': user_id,
            'username': username
        })
        
    except Exception as e:
        print(f"Error registering face: {str(e)}")
        return jsonify({'status': 'error', 'message': f'Error registering face: {str(e)}'}), 500

# Ensure database file permissions are correct
@app.route('/check-db-permissions', methods=['GET'])
def check_db_permissions():
    """Check if the database file is writable"""
    try:
        # Verify we can read the database
        if os.path.exists(DATABASE_FILE):
            with open(DATABASE_FILE, 'r') as f:
                data = json.load(f)
            readable = True
        else:
            readable = False
            
        # Verify we can write to the database
        with open(DATABASE_FILE, 'a') as f:
            pass  # Just testing append access
        writable = True
        
        # Check the directory is writable
        dir_writable = os.access(os.path.dirname(DATABASE_FILE), os.W_OK)
        
        return jsonify({
            'status': 'success',
            'readable': readable,
            'writable': writable,
            'dir_writable': dir_writable,
            'file_exists': os.path.exists(DATABASE_FILE),
            'file_size': os.path.getsize(DATABASE_FILE) if os.path.exists(DATABASE_FILE) else 0
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    # Download models if needed
    if not download_models():
        print("Error downloading models. Please check your internet connection.")
        exit(1)
        
    # Verify models are loaded correctly
    try:
        print("Initializing face detection models...")
        shape_predictor = dlib.shape_predictor(SHAPE_PREDICTOR_PATH)
        face_recognizer = dlib.face_recognition_model_v1(FACE_RECOGNITION_MODEL_PATH)
        print("Models loaded successfully!")
    except Exception as e:
        print(f"Error loading models: {e}")
        exit(1)
    
    # Ensure the database directory exists and is writable
    os.makedirs('faces', exist_ok=True)
    if not os.path.exists(DATABASE_FILE):
        with open(DATABASE_FILE, 'w') as f:
            json.dump([], f)
        print(f"Created empty database file: {DATABASE_FILE}")
    else:
        print(f"Using existing database file: {DATABASE_FILE}")
        
    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=True)
    app.run(host='0.0.0.0', port=5000, debug=True)