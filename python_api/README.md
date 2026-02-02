# Python API Server for Image Upload Testing

## Setup

1. Install Python 3.8+
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Run Server

```bash
python server.py
```

The server will start on `http://0.0.0.0:5000` (accessible from any device on your network).

## Get Your Local IP

**macOS/Linux:**
```bash
ifconfig | grep 'inet ' | grep -v 127.0.0.1
```

**Windows:**
```bash
ipconfig | findstr IPv4
```

## Test Upload

```bash
curl -X POST -F "image=@test.jpg" -F "patientId=123" -F "woundId=456" http://localhost:5000/api/upload
```

## Simulate Failures

To test retry logic, enable failure simulation:

```bash
curl -X POST http://localhost:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{"simulateFailure": true}'
```

Disable it:
```bash
curl -X POST http://localhost:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{"simulateFailure": false}'
```

## Endpoints

- `GET /` - Server status
- `POST /api/upload` - Upload image (multipart/form-data)
- `GET /api/config` - Get configuration
- `POST /api/config` - Set configuration

## Uploads Folder

All uploaded images are saved to `python_api/uploads/` with timestamp prefixes.
