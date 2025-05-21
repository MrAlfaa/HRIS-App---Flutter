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
        
        # Pre-process image to improve face detection
        # Resize if too large
        if rgb_img.shape[0] > 800 or rgb_img.shape[1] > 800:
            scale = 800 / max(rgb_img.shape[0], rgb_img.shape[1])
            rgb_img = cv2.resize(rgb_img, None, fx=scale, fy=scale)
        
        # Enhance contrast
        lab = cv2.cvtColor(rgb_img, cv2.COLOR_RGB2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        cl = clahe.apply(l)
        enhanced_lab = cv2.merge((cl, a, b))
        rgb_img = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2RGB)
        
        # Find faces with lower threshold (more sensitive)
        print("Detecting faces...")
        # Adjust detector parameters to be more sensitive
        face_locations = detector(rgb_img, 0)  # 0 = use all scales (default is 1)
        print(f"Found {len(face_locations)} faces")
        
        # If no faces found with default detector, try OpenCV's detector as backup
        if not face_locations:
            print("Trying OpenCV detector as backup...")
            face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
            gray = cv2.cvtColor(rgb_img, cv2.COLOR_RGB2GRAY)
            opencv_faces = face_cascade.detectMultiScale(gray, 1.1, 5)
            
            if len(opencv_faces) > 0:
                # Convert OpenCV face format to dlib format
                for (x, y, w, h) in opencv_faces:
                    face_locations.append(dlib.rectangle(x, y, x+w, y+h))
                print(f"OpenCV detected {len(opencv_faces)} faces")
        
        if not face_locations:
            return jsonify({'status': 'error', 'message': 'No face detected. Please try with better lighting or positioning.'}), 400
        
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
    
    for face_encoding in face_encodings:
        best_match = None
        best_distance = 0.6  # Threshold for face recognition
        
        for face in faces_db:
            stored_encoding = np.array(face['encoding'])
            # Calculate Euclidean distance
            distance = np.linalg.norm(face_encoding - stored_encoding)
            
            if distance < best_distance:
                best_match = face
                best_distance = distance
        
        if best_match:
            return jsonify({
                'status': 'success', 
                'recognized': True, 
                'userId': best_match['userId'],
                'username': best_match['username']
            })
    
    # If we get here, no match was found
    return jsonify({
        'status': 'success', 
        'recognized': False,
        'message': 'Face not recognized'
    })

@app.route('/register', methods=['POST'])
def register_face():
    if not request.json or 'image' not in request.json or 'userId' not in request.json or 'username' not in request.json:
        return jsonify({'status': 'error', 'message': 'Missing required fields'}), 400

    # Get user information
    user_id = request.json['userId']
    username = request.json['username']
    
    # Get the base64 encoded image and convert to numpy array
    encoded_data = request.json['image']
    img_data = base64.b64decode(encoded_data)
    
    # Convert to image
    image = Image.open(BytesIO(img_data))
    rgb_img = np.array(image)
    
    # Convert to BGR for OpenCV processing if needed
    if len(rgb_img.shape) == 3 and rgb_img.shape[2] == 4:  # If RGBA
        rgb_img = cv2.cvtColor(rgb_img, cv2.COLOR_RGBA2RGB)
    
    # Find faces
    face_locations = detector(rgb_img)
    
    if not face_locations:
        return jsonify({'status': 'error', 'message': 'No face detected'}), 400
    
    # Get the shape predictor
    shape_predictor = dlib.shape_predictor(SHAPE_PREDICTOR_PATH)
    face_recognizer = dlib.face_recognition_model_v1(FACE_RECOGNITION_MODEL_PATH)
    
    # Get face encoding from the first detected face
    shape = shape_predictor(rgb_img, face_locations[0])
    face_encoding = face_recognizer.compute_face_descriptor(rgb_img, shape)
    
    # Load face database
    faces_db = load_faces_db()
    
    # Create new face data
    face_data = {
        'userId': user_id,
        'username': username,
        'encoding': list(face_encoding)  # Convert to list for JSON
    }
    
    # Update or add face data
    for i, face in enumerate(faces_db):
        if face['userId'] == user_id:
            faces_db[i] = face_data
            save_faces_db(faces_db)
            return jsonify({'status': 'success', 'message': 'Face updated successfully'})
    
    # If not found, add new face
    faces_db.append(face_data)
    save_faces_db(faces_db)
    
    return jsonify({'status': 'success', 'message': 'Face registered successfully'})

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
        
    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=True)