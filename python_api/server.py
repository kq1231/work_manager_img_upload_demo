"""
Simple Python API Server for Image Upload Testing
Accepts multipart/form-data image uploads and logs them to console
"""

from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import os
from datetime import datetime

app = Flask(__name__)

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
SIMULATE_FAILURE = False  # Set to True to test retry logic

# Create upload folder if it doesn't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def home():
    return jsonify({
        'status': 'running',
        'message': 'Image Upload API Server',
        'endpoints': {
            'upload': '/api/upload (POST)',
            'config': '/api/config (GET/POST)'
        }
    })

@app.route('/api/upload', methods=['POST'])
def upload_image():
    """
    Accept multipart image upload
    Expected form data:
    - image: file
    - patientId: string (optional)
    - woundId: string (optional)
    - metadata: string (optional JSON)
    """
    
    # Simulate failure for testing
    if SIMULATE_FAILURE:
        print("❌ [SIMULATED FAILURE] Upload rejected for testing")
        return jsonify({
            'success': False,
            'error': 'Simulated failure for testing'
        }), 500
    
    # Check if image file is present
    if 'image' not in request.files:
        print("❌ [ERROR] No image file in request")
        return jsonify({
            'success': False,
            'error': 'No image file provided'
        }), 400
    
    file = request.files['image']
    
    # Check if file is empty
    if file.filename == '':
        print("❌ [ERROR] Empty filename")
        return jsonify({
            'success': False,
            'error': 'Empty filename'
        }), 400
    
    # Validate file type
    if not allowed_file(file.filename):
        print(f"❌ [ERROR] Invalid file type: {file.filename}")
        return jsonify({
            'success': False,
            'error': 'Invalid file type. Allowed: png, jpg, jpeg, gif, webp'
        }), 400
    
    # Save file
    filename = secure_filename(file.filename)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    unique_filename = f"{timestamp}_{filename}"
    filepath = os.path.join(UPLOAD_FOLDER, unique_filename)
    
    try:
        file.save(filepath)
        file_size = os.path.getsize(filepath)
        
        # Get optional metadata
        patient_id = request.form.get('patientId', 'N/A')
        wound_id = request.form.get('woundId', 'N/A')
        metadata = request.form.get('metadata', 'N/A')
        
        # Log success
        print("=" * 60)
        print("✅ [SUCCESS] Image Upload Received")
        print(f"   Filename: {unique_filename}")
        print(f"   Size: {file_size / 1024:.2f} KB")
        print(f"   Patient ID: {patient_id}")
        print(f"   Wound ID: {wound_id}")
        print(f"   Metadata: {metadata}")
        print(f"   Saved to: {filepath}")
        print(f"   Timestamp: {datetime.now().isoformat()}")
        print("=" * 60)
        
        return jsonify({
            'success': True,
            'message': 'Image uploaded successfully',
            'data': {
                'filename': unique_filename,
                'size': file_size,
                'patientId': patient_id,
                'woundId': wound_id,
                'timestamp': timestamp
            }
        }), 200
        
    except Exception as e:
        print(f"❌ [ERROR] Failed to save file: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'Failed to save file: {str(e)}'
        }), 500

@app.route('/api/config', methods=['GET', 'POST'])
def config():
    """Get or set server configuration"""
    global SIMULATE_FAILURE
    
    if request.method == 'POST':
        data = request.get_json()
        if 'simulateFailure' in data:
            SIMULATE_FAILURE = data['simulateFailure']
            print(f"⚙️  [CONFIG] Simulate failure set to: {SIMULATE_FAILURE}")
        
        return jsonify({
            'success': True,
            'config': {
                'simulateFailure': SIMULATE_FAILURE
            }
        })
    
    return jsonify({
        'config': {
            'simulateFailure': SIMULATE_FAILURE,
            'uploadFolder': UPLOAD_FOLDER,
            'allowedExtensions': list(ALLOWED_EXTENSIONS)
        }
    })

if __name__ == '__main__':
    print("\n" + "=" * 60)
    print("🚀 Image Upload API Server Starting...")
    print("=" * 60)
    print(f"   Upload folder: {os.path.abspath(UPLOAD_FOLDER)}")
    print(f"   Allowed file types: {', '.join(ALLOWED_EXTENSIONS)}")
    print(f"   Simulate failures: {SIMULATE_FAILURE}")
    print("=" * 60)
    print("\n📡 Server will be available at:")
    print("   - http://localhost:5000")
    print("   - http://<YOUR_LOCAL_IP>:5000")
    print("\n💡 Get your local IP:")
    print("   macOS/Linux: ifconfig | grep 'inet ' | grep -v 127.0.0.1")
    print("   Windows: ipconfig | findstr IPv4")
    print("\n🛑 Press Ctrl+C to stop the server\n")
    
    # Run on all interfaces so it's accessible from mobile devices
    app.run(host='0.0.0.0', port=5000, debug=True)
