function [ Obj, closed_loop_stability ] = ReturnObjectiveValue_SelfFeedback(AV_ID,N,alpha1,alpha2,alpha3,gammaType,kv,ks)
% Generate the system model and the optimal objective value
% A fixed Feedback gain is assumed

%% Parameter
switch gammaType
    
    case 1
        %S1
        gamma_s = 0.01;
        gamma_v = 0.05;
        gamma_u = 0.1;
        
    case 2
        %S2
        gamma_s = 0.03;
        gamma_v = 0.15;
        gamma_u = 0.1;
        
    case 3
        %S3
        gamma_s = 0.05;
        gamma_v = 0.25;
        gamma_u = 0.1;
    case 4
        gamma_s = 0.03;
        gamma_v = 0.15;
        gamma_u = 1;
    case 5
        gamma_s = 1;
        gamma_v = 1;
        gamma_u = 0;

end


%%


AV_number = length(find(AV_ID==1));

A1 = [0,-1;alpha1,-alpha2];
A2 = [0,1;0,alpha3];
C1 = [0,-1;alpha1-ks,-alpha2-kv];
C2 = [0,1;0,alpha3];


%Y = AY+Bu
A = zeros(2*N,2*N);
B = zeros(2*N,AV_number);
Q = zeros(2*N);
for i=1:N
    Q(2*i-1,2*i-1) = gamma_s;
    Q(2*i,2*i) = gamma_v;
end


A(1:2,1:2) = A1;
A(1:2,(2*N-1):2*N) = A2;
for i=2:N
    A((2*i-1):(2*i),(2*i-1):(2*i))=A1;
    A((2*i-1):(2*i),(2*i-3):(2*i-2))=A2;
end

% if alpha2^2-alpha3^2-2*alpha1>0
%     stability_condition_bool = true;
% else
%     stability_condition_bool = false;
% end
% 
% if isempty(find(real(eig(A))>0.001,1))
%     stable_bool = true;
% else
%     stable_bool = false;
% end


k=1;
for i=1:N
    if AV_ID(i) == 1
        if i == 1
            A(1:2,1:2) = C1;
            A(1:2,(2*N-1):2*N) = C2;
        else
            A((2*i-1):(2*i),(2*i-1):(2*i))=C1;
            A((2*i-1):(2*i),(2*i-3):(2*i-2))=C2;
        end
        B(2*i,k) = 1;
        k = k+1;
    end
end



if isempty(find(real(eig(A))>0.001,1))
    closed_loop_stability = true;
else
    closed_loop_stability = false;
end

%% Call Yalmip to calculate the optimum
epsilon   = 1e-8;


n = size(A,1);  % number of states
m = size(B,2);  % number of inputs

% assume each vehicle has a deviation
B1 = eye(n);
B1(1:2:n,1:2:n) = 0;
% B1 = B;
% assume disturbance is the same as inout
C = Q^0.5;


% variables
X = sdpvar(n);


% constraints
Constraints = [A*X  + (A*X )' + B1*B1' <=0,
    X - epsilon*eye(n)>=0];

obj   = trace(C*X*C');
%opts  = sdpsettings('solver','sedumi');   % call SDP solver: sedumi
opts  = sdpsettings('solver','mosek');     % call SDP solver: mosek, this is often better

sol     = optimize(Constraints,obj,opts);

Xd = value(X);


Obj = trace(C*Xd*C');

end

