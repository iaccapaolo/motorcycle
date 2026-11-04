clear all;

a=arduino;

carrier= motorCarrier(a)
dcm = dcmotor(carrier,'M1')
enc = rotaryEncoder(carrier,2)

dcm.start
dcm.Speed=0.5
