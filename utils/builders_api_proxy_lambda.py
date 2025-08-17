import json
import urllib.request
import urllib.error


def lambda_handler(event, context):
    """
    AWS Lambda function that acts as a proxy to the AWS Builders API.
    
    Makes a POST request to https://api.builder.aws.com/cs/content/feed
    and returns the response if successful (HTTP 200).
    """
    
    # API endpoint and request configuration
    api_url = "https://api.builder.aws.com/cs/content/feed"
    
    # Request body as specified
    request_body = {
        "contentType": "ARTICLE",
        "sort": {
            "article": {
                "sortOrder": "TRENDING_SCORE"
            }
        }
    }
    
    # Headers as specified
    headers = {
        "builder-session-token": "dummy",
        "Content-Type": "application/json"
    }
    
    try:
        # Encode request body
        data_bytes = json.dumps(request_body).encode('utf-8')

        # Prepare request
        req = urllib.request.Request(
            api_url,
            data=data_bytes,
            headers=headers,
            method='POST'
        )

        # Execute request
        with urllib.request.urlopen(req, timeout=30) as resp:
            status_code = resp.getcode()
            resp_body_bytes = resp.read()
            resp_text = resp_body_bytes.decode('utf-8') if resp_body_bytes else ''

            if status_code == 200:
                # Try to forward JSON as-is
                try:
                    parsed = json.loads(resp_text) if resp_text else {}
                    proxy_body = json.dumps(parsed)
                except json.JSONDecodeError:
                    # If not JSON, return the raw text
                    proxy_body = resp_text

                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type',
                        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS'
                    },
                    'body': proxy_body
                }

            # Non-200 from upstream
            return {
                'statusCode': status_code,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': f'API request failed with status {status_code}',
                    'message': resp_text
                })
            }

    except urllib.error.HTTPError as e:
        # HTTP error from the server
        err_text = e.read().decode('utf-8') if e.fp else ''
        return {
            'statusCode': e.code if hasattr(e, 'code') else 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Upstream HTTP error',
                'message': err_text or str(e)
            })
        }
    except urllib.error.URLError as e:
        # Network error, DNS, connection, timeout, etc.
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Network error while calling upstream',
                'message': str(e)
            })
        }
    except Exception as e:
        # Handle any other unexpected errors
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Unexpected error occurred',
                'message': str(e)
            })
        }