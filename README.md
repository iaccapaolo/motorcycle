# Self-Balancing Motorcycle – Arduino Engineering Kit Rev2

Progetto di Control Lab (M2) basato sulla moto auto-bilanciata dell'Arduino Engineering Kit Rev2: Arduino Nano 33 IoT e Nano Motor Carrier, programmati con MATLAB/Simulink.

Obiettivo: far stare in equilibrio la moto con il volano, prima da ferma e poi in movimento (rettilineo e in curva), e confrontare diverse strategie di controllo.

---

## Hardware

| Componente | Collegamento | Note |
|---|---|---|
| Nano 33 IoT | sulla Nano Motor Carrier | Wi‑Fi solo 2,4 GHz, WPA2 |
| Motore volano + encoder | **M1 / ENC1** | encoder in counts, velocità derivata in `sensor preprocessing` |
| Motore ruota posteriore (100:1) + encoder | **M2 / ENC2** | da collegare per il movimento lineare |
| Servo sterzo | porta servo della carrier | |
| IMU BNO055 | integrata nella carrier (I2C 0x28) | modalità Fusion, angolo di Eulero |
| Batteria | Li‑ion 18650 **1S (3,7 V nominali, 4,2 V da carica)** | ricaricare sotto circa 3,5 V |

## Software richiesto

- MATLAB + Simulink (licenza del kit)
- MATLAB Support Package for Arduino Hardware
- Simulink Support Package for Arduino Hardware
- Simscape, Simscape Multibody (modello fisico in `exercise_6_1`)
- Control System Toolbox (LQR)
- Arduino IDE con le librerie *ArduinoMotorCarrier*, *WiFiNINA* e *Adafruit BNO055* (solo per i test hardware)

## Struttura del repository

```
DCMotorCharacterization/   caratterizzazione motore 100:1 e controllo di velocità (DC5_closed_loop)
Motorcycle/
  exercise_6_1/            modello fisico Simscape, CAD (geometry/*.stp), modelli in spazio di stato
  exercise_6_2/            test dei singoli componenti (IMU, encoder, servo, batteria, TEST_ALL)
  exercise_6_3/            applicazione di bilanciamento (hardwareModel_0…6)
```

Gli artefatti di build (`*_ert_rtw/`, `slprj/`, `.elf`, `.bin`, `.slxc`) sono esclusi dal `.gitignore`: non vanno aggiunti al repo.

## Stato attuale

- `hardwareModel_6.slx` compila e viene caricato sul Nano 33 IoT.
- Controllore esistente: PD sull'angolo più un termine proporzionale sulla velocità del volano (`Kp = 120`, `Kd = 10`, `Kpw = 0.015`), comando saturato a ±255 su M1, Ts = 0,01 s.
- Protezioni gestite da un chart Stateflow (`enable`): moto caduta, batteria, calibrazione IMU.

---

## TODO

### 1. Verifiche hardware
- [ ] Test di motori ed encoder con lo sketch Arduino (`M1/ENC1`, `M2/ENC2`): verso di conteggio coerente con il segno del duty
- [ ] Verifica dell'IMU (scanner I2C, gravità ≈ 9,8 m/s² sull'asse verticale, angolo di Eulero coerente)
- [ ] Controllo della versione firmware della carrier e della tensione della batteria; riflashare se gli encoder danno valori anomali
- [ ] `TEST_ALL.slx` (exercise_6_2) eseguito con successo su tutti i componenti

### 2. Comunicazione
- [ ] External Mode via USB funzionante (ridurre gli scope o aumentare il baud se compare l'errore XCP *Invalid length for protocol frame*)
- [ ] External Mode via **Wi‑Fi** (XCP on WiFi):
  - [ ] hotspot a **2,4 GHz**, WPA2, SSID e password senza caratteri speciali
  - [ ] verifica con lo sketch `WiFiNINA/ScanNetworks`; aggiornare il firmware NINA se richiesto
  - [ ] MATLAB consentito nel firewall di Windows (anche sulle reti pubbliche)
  - [ ] IP della scheda visibile nel Diagnostic Viewer e raggiungibile con `ping`

### 3. Bilanciamento da fermo
- [ ] Taratura del PD esistente sulla moto reale (durata dell'equilibrio, velocità del volano)
- [ ] Ricalibrazione dell'angolo di equilibrio (offset θ₀), spostando la batteria o con una compensazione software
- [ ] Logging di θ, θ̇, velocità del volano e comando per ogni prova

### 4. Identificazione e modello
- [ ] Identificazione dei parametri del motore del volano (risposta a gradino di duty)
- [ ] Stima di I_IW, M·h_cm e I_M (risposta libera / caduta)
- [ ] Aggiornamento di `modelParameters.m` e validazione del modello Simscape contro i dati reali

### 5. Controllori da confrontare
- [ ] **LQR** su x = [θ, θ̇, φ̇] (`lqr()`), eventualmente con azione integrale (LQI)
- [ ] **Sliding mode** con σ = θ̇ + λθ e `tanh` contro il chattering, più un anello esterno sulla velocità del volano
- [ ] Confronto in simulazione (MIL) e sulla moto reale: durata dell'equilibrio, reiezione dei disturbi, saturazione del volano

### 6. Movimento lineare (`hardwareModel_7.slx`)
- [ ] Copia di `hardwareModel_6` in `hardwareModel_7`
- [ ] Ruota posteriore su **M2 / ENC2**: subsystem `Controller` di `DC5_closed_loop` (feedforward da lookup table + P)
- [ ] Blocchi Encoder e DC Motor da **arduinomotorcarrierlib**, encoder della ruota a 0,1 s, guadagno 1/100 del riduttore
- [ ] Verifica della scala del comando (DC5 lavora in ±100, il modello in ±255; probabilmente serve un fattore 2,55)
- [ ] `load('motorResponse.mat')` in `modelParameters.m`
- [ ] Nuova caratterizzazione del motore della ruota sulla propria carrier (`characterizeMotorScript.mlx`)
- [ ] Setpoint di velocità con **Rate Limiter**, comando della ruota moltiplicato per il segnale `enable`
- [ ] Prove a velocità crescente (30 → 50 → … rpm)

### 7. Sterzo e curve
- [ ] Comando del servo di sterzo con incrementi graduali (circa 5° alla volta)
- [ ] Curva a raggio costante mantenendo l'equilibrio
- [ ] (Facoltativo) uso dello sterzo come attuatore di bilanciamento in movimento / gain scheduling sulla velocità

### 8. Sicurezza
- [ ] Soglia di batteria adattata alla Rev2 (1S, circa 3,4–3,5 V) invece degli 11 V della Rev1
- [ ] Disattivazione del volano per |θ| > soglia (moto caduta)
- [ ] Limite sulla velocità del volano con latch
- [ ] Saturazione del comando ed eventuale anti‑windup

### 9. Documentazione
- [ ] Schemi Simulink dei controllori e scelte progettuali
- [ ] Grafici sperimentali (θ, θ̇, volano, ruota) per ogni controllore
- [ ] Relazione finale con il confronto tra le strategie

---

## Note operative

- Lavorare sempre su copie dei modelli in questo repo, mai nella cartella dell'add‑on in `AppData`.
- Durante i test tenere la moto sollevata o sorvegliata: se la connessione cade, il controllore continua a girare sulla scheda.
- Per tornare all'Arduino IDE dopo Simulink basta ricaricare uno sketch; prima chiudere MATLAB o eseguire `clear a`.
- I `.slx` sono binari: per confrontare due versioni usare `visdiff('a.slx','b.slx')`.
