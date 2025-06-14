# NEXT API Documentation

## Authentication Endpoints

### Sign Up
- **URL**: `/auth/signup.php`
- **Method**: `POST`
- **Description**: Register a new user
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword",
    "userType": "company|startup|seeker"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Registration successful. Please verify your email.",
    "data": {
      "userId": 1
    }
  }
  ```

### Login
- **URL**: `/auth/login.php`
- **Method**: `POST`
- **Description**: Authenticate user and get access token
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "token": "access_token_here",
      "user": {
        "id": 1,
        "email": "user@example.com",
        "userType": "company",
        "profile": {
          // Profile data based on user type
        }
      }
    }
  }
  ```

### Verify Email
- **URL**: `/auth/verify.php`
- **Method**: `GET`
- **Description**: Verify user's email address
- **Query Parameters**:
  - `token`: Verification token
- **Response**:
  ```json
  {
    "success": true,
    "message": "Email verified successfully"
  }
  ```

### Resend Verification Email
- **URL**: `/auth/resend_verification.php`
- **Method**: `POST`
- **Description**: Resend verification email
- **Request Body**:
  ```json
  {
    "email": "user@example.com"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Verification email sent"
  }
  ```

### Reset Password Request
- **URL**: `/auth/reset_password.php`
- **Method**: `POST`
- **Description**: Request password reset
- **Request Body**:
  ```json
  {
    "email": "user@example.com"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Password reset instructions sent to your email"
  }
  ```

### Update Password
- **URL**: `/auth/update_password.php`
- **Method**: `POST`
- **Description**: Update password using reset token
- **Request Body**:
  ```json
  {
    "token": "reset_token",
    "password": "newpassword"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Password updated successfully"
  }
  ```

### Logout
- **URL**: `/auth/logout.php`
- **Method**: `POST`
- **Description**: Invalidate user's session
- **Headers**:
  - `Authorization: Bearer access_token_here`
- **Response**:
  ```json
  {
    "success": true,
    "message": "Logged out successfully"
  }
  ```

## Profile Management

### Get Profile
- **URL**: `/profile/get_profile.php`
- **Method**: `GET`
- **Description**: Get user's profile information
- **Headers**:
  - `Authorization: Bearer access_token_here`
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "id": 1,
      "email": "user@example.com",
      "userType": "company",
      "profile": {
        // Profile data based on user type
      }
    }
  }
  ```

### Update Profile
- **URL**: `/profile/update_profile.php`
- **Method**: `PUT`
- **Description**: Update user's profile information
- **Headers**:
  - `Authorization: Bearer access_token_here`
- **Request Body**:
  ```json
  {
    // Profile fields to update
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Profile updated successfully",
    "data": {
      // Updated profile data
    }
  }
  ```

## File Upload

### Upload Video
- **URL**: `/upload/video.php`
- **Method**: `POST`
- **Description**: Upload a video file
- **Headers**:
  - `Authorization: Bearer access_token_here`
- **Request Body**: `multipart/form-data`
  - `video`: Video file
  - `title`: Video title
  - `description`: Video description
- **Response**:
  ```json
  {
    "success": true,
    "message": "Video uploaded successfully",
    "data": {
      "videoId": 1,
      "url": "video_url_here"
    }
  }
  ```

### Delete Video
- **URL**: `/upload/delete_video.php`
- **Method**: `DELETE`
- **Description**: Delete a video file
- **Headers**:
  - `Authorization: Bearer access_token_here`
- **Request Body**:
  ```json
  {
    "videoId": 1
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Video deleted successfully"
  }
  ```

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "success": false,
  "message": "Invalid request parameters"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Resource not found"
}
```

### 429 Too Many Requests
```json
{
  "success": false,
  "message": "Too many attempts. Please try again later.",
  "retry_after": 60
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "An error occurred while processing your request"
}
```

## Rate Limiting

API endpoints are rate limited to prevent abuse. The current limits are:
- 60 requests per minute per IP address
- Rate limit headers are included in responses:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Time until limit resets

## Authentication

Most endpoints require authentication using a Bearer token:
```
Authorization: Bearer access_token_here
```

The token is obtained during login and should be included in the request headers for protected endpoints.

## File Upload Limits

- Maximum file size: 10MB
- Allowed video formats: MP4, MOV, AVI
- Allowed image formats: JPG, JPEG, PNG, GIF
- Allowed document formats: PDF, DOC, DOCX 