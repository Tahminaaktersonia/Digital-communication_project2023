function codedBits = encodeBits(sourceBits)

P = [1 0 1; 1 1 1; 1 1 0; 0 1 1];

% Generator matrix G
G = [eye(4) P];
    
    % Number of source bits and coded bits
    k = 4;
   % n = size(G, 1);
   n= 2;

    % Reshape source bits into a matrix
    sourceBits = randi([0 1], 1, 10000); % Generate random source bit sequence
    sourceMatrix = reshape(sourceBits, k, []).';

    % Perform matrix multiplication to obtain coded bits
    codedMatrix = mod(sourceMatrix * G, 2);

    % Convert coded matrix back to a bit sequence
    codedBits = reshape(codedMatrix.', 1, []);
end
