% Initialization
    numIterations = 1000;
    stepSize = 0.01;
    filterLength = 30;
    equalizerCoefficients = zeros(1, filterLength);
    Nd=20;
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
noise = noise(1:length(receivedSignalDownsampled));
if length(noise) < i+order-1
    % Extend the noise array by repeating its elements
    numRepeats = ceil((i+order-1) / length(noise));
    noise = repmat(noise, 1, numRepeats);
    noise = noise(1:i+order-1);
elseif length(noise) > i+order-1
    % Truncate the noise array to the required length
    noise = noise(1:i+order-1);
end

% Compute the update term
update = stepSize * conj(noise) * receivedSignalDownsampled(i:i+order-1);

receivedSignal = channelOutput + noise;
    
    % Perform equalization
  function equalizerOutput = lmsEqualizer(receivedSignal, trainingSymbols, Nd, M)
    % Initialize equalizer coefficients
    equalizerCoefficients = zeros(Nd, 1);
    
    % Initialize step size
    stepSize = 0.01;
    
    % Perform LMS equalization
    for i = 1:numel(receivedSignal)
        % Extract chunk of received signal
        chunk = receivedSignal(i:i+Nd-1);
        
        % Compute equalizer output
        equalizerOutput = equalizerCoefficients' * chunk.';
        
        % Compute error
        error = trainingSymbols(i) - equalizerOutput;
        
        % Update equalizer coefficients
        equalizerCoefficients = equalizerCoefficients + stepSize * conj(error) * chunk;
    end
    
    % Apply equalizer to the whole received signal
    equalizerOutput = conv(receivedSignal, equalizerCoefficients, 'valid');
end
