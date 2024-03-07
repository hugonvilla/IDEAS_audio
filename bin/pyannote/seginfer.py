#!/usr/bin/python
import sys
from pyannote.audio import Model,Inference
from pyannote.audio.tasks import VoiceActivityDetection
from pyannote.database import get_protocol
import scipy.io

def main():
    test_file = sys.argv[1]

    ami = get_protocol('temp_protocol.SpeakerDiarization.All')

    model = Model.from_pretrained(sys.argv[2])
    model.task = VoiceActivityDetection(ami)
    inference_vad = Inference(model)
    vad_probability = inference_vad(test_file)
    Tnp_vad = vad_probability.data.T;
    scipy.io.savemat('vad.mat', {'mydata': Tnp_vad})

if __name__ == '__main__':
    main()


    
     