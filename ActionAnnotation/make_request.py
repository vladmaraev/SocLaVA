import cv2
import base64
import requests
import json
import time

url = "http://localhost:10012/api/generate"

img = cv2.imread('/Users/xmarvl/Downloads/frame_049385.jpg')
jpg_img = cv2.imencode('.jpg', img)
b64_string = base64.b64encode(jpg_img[1]).decode('utf-8')

payload = {"model": "llava:34b-v1.6",
           "prompt":"What is in this picture?",
           "stream": False,
           "images": [b64_string]}

t1 = time.time()
print(t1)
r = requests.post(url, data=json.dumps(payload))
t2 = time.time()
print(t2)
print(r.text)
print(t2 - t1)
