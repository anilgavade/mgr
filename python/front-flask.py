import matlab.engine
from flask import Flask,url_for
from flask import render_template, request
from flask import jsonify
from flask_cors import CORS
import unicodedata

app = Flask(__name__)
# app._static_folder = './static'
CORS(app)

matlab_engine = matlab.engine.start_matlab()

def normalize_unicode_string(data):
    return unicodedata.normalize('NFKD', data).encode('ascii','ignore')

@app.route("/")
def hello():
    return "Hello World!"

@app.route("/images")
def images():
        return render_template('main.html')

@app.route("/images",methods = ['POST'])
def showResult():
    if request.method == 'POST':
        payload  = request.get_json()
        # callback = matlab_engine.fn(1.0,5.0)
        image_name = normalize_unicode_string(payload['fileName'])
        print(image_name,'---------------------------------------')
        matlab_engine.seed_mean_py(image_name,nargout=0)     
        return jsonify({'result':'callback'})

@app.route("/matlab")
def matlab():
    return "some matlab content"

if __name__ == "__main__":
    app.debug = True
    app.run()


