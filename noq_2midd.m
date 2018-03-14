pkg load queueing

%S_client=0
%S_network=0.0007
%S_netthread=0.0000137962619998
%S_worker=0.00368372298013
%
%m_netthread=1
%m_worker=32
%
%P = [ 0 0.5 0.5 0 0 0 0 0;
%      0 0   0   1 0 0 0 0;
%      0 0   0   0 1 0 0 0;
%      0 0   0   0 0 1 0 0;
%      0 0   0   0 0 0 1 0;
%      0 0   0   0 0 0 0 1;
%      0 0   0   0 0 0 0 1;
%      1 0   0   0 0 0 0 0 ];
%V = qncsvisits(P);
%
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=60
%Z=0
%
%[U R Q X] = qnsolve("closed", N, QQ, V, Z);
%
%U
%R
%Q
%X

%S_client=0.007
%%S_network=0.0029
%S_network=0.00142
%S_netthread=0.0000137962619998
%S_worker=0.00368372298013
%
%m_netthread=1
%m_worker=32
%
%P = [ 0 0.5 0.5 0 0 0 0 0;
%      0 0   0   1 0 0 0 0;
%      0 0   0   0 1 0 0 0;
%      0 0   0   0 0 1 0 0;
%      0 0   0   0 0 0 1 0;
%      0 0   0   0 0 0 0 1;
%      0 0   0   0 0 0 0 1;
%      1 0   0   0 0 0 0 0 ];
%V = qncsvisits(P);
%
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=168
%Z=0
%
%[U R Q X] = qnsolve("closed", N, QQ, V, Z);
%
%U
%R
%Q
%X


%S_client=0
%S_network=0.002
%S_netthread=0.0000137962619998
%S_worker=0.00368372298013
%
%m_netthread=1
%m_worker=32
%
%P = [ 0 0.5 0.5 0 0 0 0 0;
%      0 0   0   1 0 0 0 0;
%      0 0   0   0 1 0 0 0;
%      0 0   0   0 0 1 0 0;
%      0 0   0   0 0 0 1 0;
%      0 0   0   0 0 0 0 1;
%      0 0   0   0 0 0 0 1;
%      1 0   0   0 0 0 0 0 ];
%V = qncsvisits(P);
%
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=256
%Z=0
%
%[U R Q X] = qnsolve("closed", N, QQ, V, Z);
%
%U
%R
%Q
%X



%S_client=0
%S_network=0.001
%S_netthread=0.0000116611293403
%S_worker=0.00208475077866
%
%m_netthread=1
%m_worker=8
%
%P = [ 0 0.5 0.5 0 0 0 0 0;
%      0 0   0   1 0 0 0 0;
%      0 0   0   0 1 0 0 0;
%      0 0   0   0 0 1 0 0;
%      0 0   0   0 0 0 1 0;
%      0 0   0   0 0 0 0 1;
%      0 0   0   0 0 0 0 1;
%      1 0   0   0 0 0 0 0 ];
%V = qncsvisits(P);
%
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=60
%Z=0
%
%[U R Q X] = qnsolve("closed", N, QQ, V, Z);
%
%U
%R
%Q
%X

%S_client=0
%S_network=0.001
%S_netthread=0.0000116611293403
%S_worker=0.00208475077866
%
%m_netthread=1
%m_worker=8
%
%P = [ 0 0.5 0.5 0 0 0 0 0;
%      0 0   0   1 0 0 0 0;
%      0 0   0   0 1 0 0 0;
%      0 0   0   0 0 1 0 0;
%      0 0   0   0 0 0 1 0;
%      0 0   0   0 0 0 0 1;
%      0 0   0   0 0 0 0 1;
%      1 0   0   0 0 0 0 0 ];
%V = qncsvisits(P);
%
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=168
%Z=0.017
%
%[U R Q X] = qnsolve("closed", N, QQ, V, Z);
%
%U
%R
%Q
%X


S_client=0
S_network=0.001
S_netthread=0.0000116611293403
S_worker=0.00208475077866

m_netthread=1
m_worker=8

P = [ 0 0.5 0.5 0 0 0 0 0;
      0 0   0   1 0 0 0 0;
      0 0   0   0 1 0 0 0;
      0 0   0   0 0 1 0 0;
      0 0   0   0 0 0 1 0;
      0 0   0   0 0 0 0 1;
      0 0   0   0 0 0 0 1;
      1 0   0   0 0 0 0 0 ];
V = qncsvisits(P);

QQ = { qnmknode("-/g/inf", S_client),
       qnmknode("-/g/inf", S_network),
       qnmknode("-/g/inf", S_network),
       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
       qnmknode("m/m/m-fcfs", S_worker, m_worker),
       qnmknode("m/m/m-fcfs", S_worker, m_worker),
       qnmknode("-/g/inf", S_network) };
       
N=256
Z=0.0349

[U R Q X] = qnsolve("closed", N, QQ, V, Z);

U
R
Q
X