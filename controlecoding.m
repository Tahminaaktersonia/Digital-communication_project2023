% Step 1: Encode the original bit sequence with a Hamming code

% Define the generator matrix G
G = [eye(4), [1 0 1; 1 1 1; 1 1 0; 0 1 1]];

% Original bit sequence
sourceBits = randi([0, 1], 1, N);  % N is the length of the original bit sequence

% Encode the source bits
codedBits = mod(sourceBits *G, 2);

% Step 2: Decode the received, coded bit sequence

% Define the parity check matrix H
H = [1 1 0; 1 0 1; 1 1 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1];

% Received, coded bit sequence
receivedCodedBits = receivedBits;  % Replace with your received coded bit sequence

% Ignore/discard the bits at the end that are not multiples of the codeword length
numCodewords = floor(length(receivedCodedBits) / 7);
receivedCodedBits = receivedCodedBits(1:numCodewords * 7);

% Reshape the received coded bits into codewords
receivedCodewords = reshape(receivedCodedBits, 7, []).';

% Decode the received codewords
decodedCodewords = mod(receivedCodewords * H.', 2);

% Correct errors using the decoding table (single bit error correction)
decodingTable = [eye(7); [1, zeros(1, 6)]; [zeros(1, 6), 1]];
syndromes = mod(decodedCodewords * decodingTable.', 2);
errorIndices = bi2de(syndromes, 'left-msb') + 1;
decodedCodewords(errorIndices ~= 1, :) = mod(decodedCodewords(errorIndices ~= 1, :) + decodingTable(errorIndices ~= 1, :), 2);

% Retrieve the decoded source bits
decodedBits = decodedCodewords(:, 1:4);

% Reshape decodedBits to a single row vector
decodedBits = reshape(decodedBits.', 1, []);

% Step 3: Repeat simulation for different SNRs (0 dB to 20 dB) and compute BERs

SNRs = 0:20;  % SNRs in dB
numSNRs = length(SNRs);
BERs = zeros(1, numSNRs);

for i = 1:numSNRs
    % Add noise to the received coded bits at the desired SNR
    receivedCodedBitsWithNoise = awgn(receivedCodedBits, SNRs(i), 'measured');
    
    % Perform decoding and error correction as shown in Step 2
    
    % Compute bit error rate (BER)
    numErrors = sum(receivedCodedBitsWithNoise ~= receivedCodedBits);
    BERs(i) = numErrors / length(receivedCodedBits);
end

% Step 4: Plot the BER values as a function of SNR
figure;
plot(SNRs, BERs);
title('Bit Error Rate (BER) vs SNR');
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
