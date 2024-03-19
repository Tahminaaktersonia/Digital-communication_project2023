%Name:Tahmina Akter
%Student ID: 151349966
%tahmina.akter@tuni.fi
%% 1
% Parameters
M = 4;                          % M-QAM modulation
Rs = 40e6;                      % Symbol rate (symbols/s)
Ts = 1 / Rs;                    % Symbol period (s)
numBits = log2(M) * 100000;     % Number of bits
rollOffFactor = 0.40;
durationSymbols = 20;
Oversamplingfactor = 4;
FsT = 4;                % Over-sampling factor
n= 2;
%% 1

% Step 1: Generate random bits
bits = randi([0 1], 1, numBits);

% Step 2: Channel encoder (optional)
encodedBits = bits;

% Step 3: Gray mapping for M-QAM symbols
symbolIndices = bin2gray(reshape(bits, log2(M), []).', 'qam', M);
symbols = alphabet(Gray_symbol_indices+1);

% Plot constellation diagram 
scatterplot(symbols);
title('Constellation Diagram');
grid on;
%%

% Step 4: Up-sample symbols
FsT = 4;                % Over-sampling factor
upSampledSymbols = upsample(symbols, FsT);

% Step 5: Pulse-shape filtering with RRC filter
rollOffFactor = 0.40;
durationSymbols = 20;
rrcFilter = rcosdesign(rollOffFactor, durationSymbols, FsT);
filteredSignal = conv(upSampledSymbols, rrcFilter);

% Correct for filter delay
filterDelay = (length(rrcFilter) - 1) / 2;
filteredSignal = filteredSignal(filterDelay+1:end-filterDelay);
%%
% Plot eye diagram
n = 2;                      % Number of signal blocks
signalBlockLength = n * FsT;
eyeDiagram = reshape(real(filteredSignal), signalBlockLength, []);
plot(eyeDiagram);
title('Eye Diagram');
xlabel('Time');
ylabel('Amplitude');
grid on;
%%
% Examine spectral content
transmitFilterFreqResponse = freqz(rrcFilter, 1, 'whole', FsT);
%transmitFilterFreq = -FsT/2 : 1 : FsT/2;
transmitFilterFreq = linspace(-FsT/2, FsT/2, numel(transmitFilterFreqResponse));

figure;
subplot(2, 1, 1);
plot(transmitFilterFreq, abs(transmitFilterFreqResponse));
%plot(transmitFilterFreq, (transmitFilterFreqResponse));
title('Amplitude Response of Transmit Filter');
xlabel('Frequency');
ylabel('Magnitude');
grid on;

transmittedSignalFreq = fftshift(fft(filteredSignal));
transmittedSignalFreqAxis = -Rs/2 : Rs/(length(transmittedSignalFreq)-1) : Rs/2;
subplot(2, 1, 2);
plot(transmittedSignalFreqAxis, abs(transmittedSignalFreq));
title('Amplitude Spectrum of Transmitted Signal');
xlabel('Frequency');
ylabel('Magnitude');
grid on;

%% Part 2: Transmission over Channel
% Channel impulse response
channelImpulseResponse = [-0.5261 - 0.4737i, -0.6539 + 0.6056i, 0.5204 - 0.1049i, 0.3381 + 0.2919i, 0.1877 + 0.2545i];

% Correct for channel delay
channelDelay = find(abs(channelImpulseResponse) == max(abs(channelImpulseResponse)), 1) - 1;
channelOutput = conv(filteredSignal, channelImpulseResponse);
channelOutput = channelOutput(channelDelay+1:end);

% Add white Gaussian noise
SNR_dB = 15;
signalPower = mean(abs(channelOutput).^2);
noisePower = signalPower / (10^(SNR_dB/10));
noise = sqrt(noisePower/2) * (randn(size(channelOutput)) + 1i * randn(size(channelOutput)));
receivedSignal = channelOutput + noise;

% Plot channel frequency response
channelFreqResponse = freqz(channelImpulseResponse, 1, 'whole', FsT);
%channelFreq = -FsT/2 : 1 : FsT/2;
channelFreq = linspace(-FsT/2, FsT/2, numel(channelFreqResponse));
figure;
subplot(2, 1, 1);
plot(channelFreq, abs(channelFreqResponse));
title('Channel Frequency Response (Amplitude)');
xlabel('Frequency');
ylabel('Magnitude');
grid on;

subplot(2, 1, 2);
plot(channelFreq, angle(channelFreqResponse));
title('Channel Frequency Response (Phase)');
xlabel('Frequency');
ylabel('Phase (radians)');
grid on;

% Amplitude spectrum of received signal
receivedSignalFreq = fftshift(fft(receivedSignal));
receivedSignalFreqAxis = -Rs/2 : Rs/(length(receivedSignalFreq)-1) : Rs/2;
figure;
subplot(2, 1, 1);
plot(receivedSignalFreqAxis, abs(receivedSignalFreq));
title('Amplitude Spectrum of Received Signal');
xlabel('Frequency');
ylabel('Magnitude');
grid on;

% Compare with amplitude spectrum of transmitted signal
subplot(2, 1, 2);
plot(transmittedSignalFreqAxis, abs(transmittedSignalFreq));
title('Amplitude Spectrum of Transmitted Signal');
xlabel('Frequency');
ylabel('Magnitude');
grid on;
%% 2.3

% Receiver
% Receiver Side

%rollOffFactor = 0.40;
rollOffFactor = 0.40;
durationSymbols = 20;
rrcFilter = rcosdesign(rollOffFactor, durationSymbols, FsT);
%filterSpan = ceil((2 * rollOffFactor) / durationSymbols);
% Compute the filter duration
%filterDuration = ceil((4 * filterSpan / durationSymbols) / (2 * rollOffFactor));
% Step 1: Filter the received signal with a matched filter (square-root raised-cosine)
%receivedSignalFiltered = conv(receivedSignal, rrcFilter);   % Convolve with the matched filter impulse response
%receivedSignalFiltered = receivedSignalFiltered(filterDuration:end-(filterDuration-1));   % Remove filter delay

% Step 2: Down-sample the signal to the symbol rate
Nd= 20;
% Matched filter (RRC filter)
receivedSignalMatched = conv(receivedSignal, rrcFilter, 'same');

% Correct for filter delay
receivedSignalMatched = receivedSignalMatched(Nd/2+1:end);

% Plot eye diagram of received signal
eyediagram(real(receivedSignalMatched), 2 * Nd);
title('Received Signal Eye Diagram');

% Downsample the signal
downsampledSignal = downsample(receivedSignalMatched, FsT);

% Plot symbol constellation of downsampled signal
scatterplot(downsampledSignal);
title('Downsampled Signal Constellation');

%receivedSignalDownsampled = downsample(receivedSignalFiltered, Oversamplingfactor);   % Down-sample to symbol rate

% Step 3: Least Mean Squares (LMS) Algorithm-based Equalizer
order = 30;                          % Equalizer order/length
stepSize = 0.01;                     % LMS step size
iterations = 1000;                   % Number of iterations

trainingSeq = randi([0, 1], 1, length(receivedSignalDownsampled));   % Generate training sequence

% Initialize equalizer weights
%equalizerWeights = zeros(1, order);

%qualizerWeights = zeros(1, order);  % Initialize equalizer weights
equalizerWeights = zeros(1, order);  % Initialize equalizer weights
for i = 1:length(noise)-order+1
    % Compute the update for equalizer weights
    update = stepSize * conj(noise(i)) * receivedSignalDownsampled(i:i+order-1);
    equalizerWeights = equalizerWeights + update;
end

% Equalize the whole received signal
equalizedSignal = conv(receivedSignalDownsampled, equalizerWeights, 'same');

%% Step 4: Plot the LMS error
figure;
plot(abs(noise).^2);
title('LMS Error');
xlabel('Iteration');
ylabel('Error');

%% Step 5: Plot the frequency and phase response of the equalizer and channel
frequencyResponseEqualizer = fft(equalizerWeights, 1024);
frequencyResponseChannel = fft(channelImpulseResponse, 1024);

figure;
subplot(2,1,1);
plot(abs(frequencyResponseEqualizer));
hold on;
plot(abs(frequencyResponseChannel));
title('Frequency Response');
xlabel('Frequency');
ylabel('Magnitude');
legend('Equalizer', 'Channel');

subplot(2,1,2);
plot(angle(frequencyResponseEqualizer));
hold on;
plot(angle(frequencyResponseChannel));
title('Phase Response');
xlabel('Frequency');
ylabel('Phase');
legend('Equalizer', 'Channel');

%% Step 6: Plot the constellation of the equalized signal

%symbolIndices = bin2gray(reshape(bits, log2(M), []).', 'qam', M);
%symbols = alphabet(Gray_symbol_indices+1);
equalizedSignal = conv(receivedSignalDownsampled, equalizerWeights, 'same');
%constellationEqualized = equalizedSignal / max(abs(equalizedSignal));   % Normalize the equalized signal
constellationTransmitted = symbols / max(abs(symbols));                 % Normalize the transmitted symbols
figure;
scatterplot(equalizedSignal);
hold on;
scatterplot(constellationTransmitted);
title('Equalized Signal Constellation');
legend('Equalized', 'Transmitted');

%% 2.4 Error Control Coding
% Step 4: Equalize the entire received sample sequence using the obtained equalizer filter

equalizedSignal = conv(downSampledSignal, equalizer);

% Correct for equalizer delay
equalizedSignal = equalizedSignal(order+1:end);

%Step 5: Detect the received equalized samples using a symbol-by-symbol minimum distance detector
detectedSymbols = qamdemod(equalizedSignal, M);

% Correct for symbol delay
detectedSymbols = detectedSymbols(durationSymbols*FsT+1:end);
%Step 6: Use the Gray decoder to obtain the coded bits

%decodedBits = reshape(de2bi(gray2bin(detectedSymbols, M)-1, log2(M), 'left-msb').', 1, []);

symbolIndices = bin2gray(reshape(detectedSymbols, log2(M), []).', 'qam', M);
decodedBits = reshape(de2bi(symbolIndices, log2(M), 'left-msb').', 1, []);


%Step 7: part:2,Decode the received, coded bit sequence using a Hamming decoder
% Assuming receivedBits is the received bit sequence

% Parameters
M = 4;  % Modulation order (4-QAM)
k = 4;  % Source bit length

% Generate random bit sequence
originalBits = randi([0, 1], 1, k);

% Modulation
modulatedSymbols = qammod(originalBits, M);

% Channel effects and noise
SNR_dB = 10;  % Signal-to-Noise Ratio in dB
receivedSymbols = awgn(modulatedSymbols, SNR_dB, 'measured');

% Demodulation
demodulatedBits = qamdemod(receivedSymbols, M);

% Convert symbol indices to binary
receivedBits = reshape(de2bi(demodulatedBits, log2(M), 'left-msb').', 1, []);

% Remove trailing bits that are not multiples of the bit length
receivedBits = receivedBits(1:length(originalBits));

% Compare with demodulated bits
calculteErrors = sum(demodulatedBits ~= receivedBits);
bitErrorRate = calculteErrors/ length(demodulatedBits);

% Display results
disp("Original Bits: " + mat2str(originalBits))
disp("Received Bits: " + mat2str(receivedBits))
disp("Bit Error Rate: " + bitErrorRate)

n = 7;  % Coded bit length
k = 4;  % Source bit length
parityCheckMatrix = [1 1 0; 1 0 1; 1 1 1; 0 1 1];
calculateBlocks = floor(length(receivedBits) / n);

decodedBits = zeros(1, calculateBlocks * k); % Initialize decoded bits vector

% Iterate over blocks of received bits and decode each block
for i = 1:numBlocks
    block = receivedBits((i-1)*n + 1 : i*n); % Extract a block of received bits
    
    % Check for errors using the parity check matrix
    syndrome = mod(parityCheckMatrix * block', 2);
    
    % Correct single-bit errors if any
    if any(syndrome)
        errorBitIndex = bi2de(fliplr(syndrome)) + 1;
        block(errorBitIndex) = ~block(errorBitIndex);
    end
    
    % Extract the source bits from the decoded block
    decodedBits((i-1)*k + 1 : i*k) = block(1:k);
end

% Remove trailing bits that are not multiples of the codeword length
decodedBits = decodedBits(1:floor(length(decodedBits)/n)*n);

%Step 8: Compute the bit error rate (BER)
% Assuming originalBits and decodedBits are the original transmitted and decoded bit sequences, respectively

% Make sure both sequences have the same length
minLength = min(length(originalBits), length(decodedBits));
originalBits = originalBits(1:minLength);
decodedBits = decodedBits(1:minLength);

% Compute the number of errors
calculatteErrors = sum(bitxor(originalBits, decodedBits));

bitErrorRate = calculatteErrors / length(originalBits);


%% 2.4.3
%Step 9: Repeat the simulation for different SNR values and compute BERs
% Set the SNR range
snrRange = 0:1:20;

% Set the target BER
targetBER = 1e-3;

% Initialize arrays to store BER values
berWithCoding = zeros(size(snrRange));
berWithoutCoding = zeros(size(snrRange));



% Run the simulation for each SNR value
for i = 1:length(snrRange)
    % Generate random source bits
    sourceBits = randi([0 1], 1, 17500); % Adjust the length as per your requirement

    % Apply error control coding (Hamming code)
  

% Step 2: Channel encoder (optional)

numBits = log2(M) * 100000; 
 bits = randi([0 1], 1, numBits);
encodedBits = bits;

    codedBits = encodeBits(sourceBits);

    % Add AWGN to the coded bits
    snr = snrRange(i);
    receivedBits = addAWGN(codedBits, snr);
n= 2;
    % Decode the received bits
    calculateBlocks = floor(length(receivedBits) / n);
    


%decodedBits = zeros(1, calculateBlocks * k); 
    decodedBits = decodeHamming(receivedBits);

    % Compute the BER with coding
    calculateErrorsWithCoding = sum(sourceBits ~= decodedBits);
    berWithCoding(i) = calculateErrorsWithCoding / length(sourceBits);

    % Compute the BER without coding
    calculateErrorsWithoutCoding = sum(sourceBits ~= receivedBits);
    berWithoutCoding(i) = calculateErrorsWithoutCoding / length(sourceBits);
end

% Find the SNR at the target BER
%snrAtTargetBER = interp1(berWithCoding, snrRange, targetBER);
targetBER = 1.0000e-03;  % Target BER
tolerance = 1e-5;  % Tolerance for BER comparison

snrAtTargetBER = NaN;  % Initialize SNR value

for i = 1:length(berWithCoding)
    if abs(berWithCoding(i) - targetBER) < tolerance
        snrAtTargetBER = snrRange(i);
        break;
    end
end

if isnan(snrAtTargetBER)
    % Target BER not found within the provided data
    % Handle the case as desired
end


% Plot the BER values
figure;
semilogy(snrRange, berWithCoding, '-o', 'DisplayName', 'With Coding');
hold on;
semilogy(snrRange, berWithoutCoding, '-o', 'DisplayName', 'Without Coding');
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs. SNR');
grid on;
legend;

% Display the SNR at the target BER
fprintf('SNR at target BER of %e: %f dB\n', targetBER, snrAtTargetBER);

