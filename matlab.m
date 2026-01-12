clc; clear; close all;
savej_path = 'Original File Location'; 
saveY_path = 'File Location'; 
if ~exist(savej_path, 'dir')
    mkdir(savej_path);
end
if ~exist(saveY_path, 'dir')
    mkdir(saveY_path);
end
[x, fs0] = audioread([savej_path, 'File name']);
x = mean(x,2);           
fs = 8000;               
x = resample(x, fs, fs0);
t = (0:length(x)-1)/fs;  
figure;
subplot(2,1,1);
plot(t, x);
title('Original Speech Time Domain');
xlabel('Time / s'); ylabel('Amplitude');
N = length(x);                   
f = (0:N-1)*fs/N;               
X = abs(fft(x));                
subplot(2,1,2);
plot(f(1:N/2), X(1:N/2));       
title('Original Speech Frequency Spectrum');
xlabel('Frequency / Hz');
audiowrite([savej_path, 'Originahl_Speech_8kHz.wav'], x, fs);
fprintf(' Playing: Original Speech (8 kHz)...\n');
sound(x, fs);                    
pause(length(x)/fs+1);           
bp = fir1(800, [300 3000]/(fs/2), 'bandpass');
plot_filter_response(bp, fs, '300-3000Hz Bandpass Filter', savej_path);
x_bp = filter(bp,1,x);           
figure;
subplot(2,1,1);
plot(t, x_bp);
title('Time Domain After Bandpass Filteringh');
Xbp = abs(fft(x_bp));            
subplot(2,1,2);
plot(f(1:N/2), Xbp(1:N/2));
title('Frequency Spectrum After Bandpass Filtering');
audiowrite([savej_path, 'Speech_After_Bandpass.wav'], x_bp, fs);
fprintf(' Playing: Speech After Bandpass Filtering (300¨C3000 Hz)...\n');
sound(x_bp, fs);                 
pause(length(x)/fs+1);
fc = 4000;   
carrier = cos(2*pi*fc*t');       
x_mod = x_bp .* carrier;         
lp = fir1(800, 3500/(fs/2), 'low');
plot_filter_response(lp, fs, '3500Hz Lowpass Filter', savej_path);
x_enc = filter(lp,1,x_mod);     
figure;      
subplot(2,1,1);
plot(t, x_enc);
title('Time Domain of Cepstrum Encrypted Signal');
Xenc = abs(fft(x_enc));          
subplot(2,1,2);
plot(f(1:N/2), Xenc(1:N/2));
title('Frequency Spectrum of Cepstrum Encrypted Signal');
audiowrite([savej_path, 'Encrypted_Speech.wav'], x_enc, fs);
fprintf(' Playing: Cepstrum Encrypted Speech (Encrypted)...\n');
sound(x_enc, fs);                
pause(length(x)/fs+1);
x_demod = x_enc .* carrier;      
x_dec = filter(lp,1,x_demod);    
figure;     
subplot(2,1,1);
plot(t, x_dec);
title('Time Domain of Decrypted Signal');
Xdec = abs(fft(x_dec));          
subplot(2,1,2);
plot(f(1:N/2), Xdec(1:N/2));
title('Frequency Spectrum of Decrypted Signal');
audiowrite([savej_path, 'Decrypted_Speech.wav'], x_dec, fs);
fprintf(' Playing: Decrypted Speech (Original Content Recovered)...\n');
sound(x_dec, fs);                
pause(length(x)/fs+1);
files = dir([saveY_path, 'File name']);
lp_pojie = fir1(800, 3500/(fs/2), 'low');    
plot_filter_response(lp_pojie, fs, '3500Hz Lowpass Filter for Cracking', saveY_path);
for k = 1:length(files)
    [y, fs1] = audioread(fullfile(files(k).folder, files(k).name));
    y = mean(y,2);                       
    y = resample(y, fs, fs1);              
    len_y = length(y);                     
    t2 = (0:len_y-1)/fs;                   
    y_duration = len_y/fs;                 
    fprintf('\n========== Cracking File: %s ==========\n', files(k).name);
    for fc_try = 2800:50:3500
        carrier_try = cos(2*pi*fc_try*t2');
        y_demod = y .* carrier_try;         
        y_try = filter(lp_pojie,1,y_demod);
        pojie_filename = [saveY_path, ...
            'Crack_Attempt_', num2str(fc_try), 'Hz.wav'];
        audiowrite(pojie_filename, y_try, fs);
        fprintf('Playing cracked speech: fc = %d Hz (Please judge clarity)...\n', fc_try);
        sound(y_try, fs);
        pause(y_duration);
        pause(2);           
    end
    fprintf('========== Cracking Attempt for %s Completed ==========\n\n', files(k).name);
    pause(1);
end
fprintf('Encrypted speech saved to: %s\n', savej_path);
fprintf(' Cracked speech saved to: %s\n', saveY_path);

function plot_filter_response(b, fs, filter_name, saveh_path)
    [h, f] = freqz(b, 1, 1024, fs);
    mag_dB = 20*log10(abs(h));      
    phase = unwrap(angle(h));       
    figure('Name', [filter_name, ' Frequency Response']);
    subplot(2,1,1);
    plot(f, mag_dB);
    title([filter_name, ' Magnitude Response (dB)']);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    grid on;
    ylim([-80, 10]);
    subplot(2,1,2);
    plot(f, phase);
    title([filter_name, ' Phase Response (rad)']);
    xlabel('Frequency (Hz)');
    ylabel('Phase (rad)');
    grid on;
    saveas(gcf, [saveh_path, filter_name, '_Frequency_Response.png']);
end