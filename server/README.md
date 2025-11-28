# LocalPictureSaver Server

A FastAPI backend to receive, store, and serve uploaded photos/videos from your iOS app.

## Features
- Token-based authentication
- Upload multiple files
- List all uploaded files
- Download any file
- Organizes uploads by date

## Setup
1. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
2. Copy `.env` and set your own `API_TOKEN`.
3. Run the server:
   ```
   uvicorn main:app --reload
   ```

## API Endpoints
- `POST /upload` (token required): Upload one or more files
- `GET /files` (token required): List all uploaded files
- `GET /download/{file_path}` (token required): Download a file

## Notes
- Files are stored in the `uploads/` directory, organized by date.
- Use HTTPS in production.
