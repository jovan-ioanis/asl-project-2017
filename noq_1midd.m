pkg load queueing

%S_client=0
%S_network=0
%S_netthread=0.00000395579475389
%S_worker=0.00277045772859
%
%m_netthread=1
%m_worker=32
%
%P = [ 0 1 0 0 0;
%      0 0 1 0 0;
%      0 0 0 1 0;
%      0 0 0 0 1;
%      1 0 0 0 0];
%V = qncsvisits(P);
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=10
%Z=0

%[U R Q X] = qnsolve("closed", N, QQ, V, Z);

%S_client=0.000000001
%S_network=0
%S_netthread=0.00000395579475389
%S_worker=0.00277045772859
%
%m_netthread=1
%m_worker=32
%
%P = [ 0 1 0 0 0;
%      0 0 1 0 0;
%      0 0 0 1 0;
%      0 0 0 0 1;
%      1 0 0 0 0];
%V = qncsvisits(P);
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=30
%Z=0

#[U R Q X] = qnsolve("closed", N, QQ, V, Z);


%S_client=0
%S_network=0.0023
%S_netthread=0.00000395579475389
%S_worker=0.00277045772859
%
%m_netthread=1
%m_worker=32
%
%P = [ 0 1 0 0 0;
%      0 0 1 0 0;
%      0 0 0 1 0;
%      0 0 0 0 1;
%      1 0 0 0 0];
%V = qncsvisits(P);
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=84
%Z=0

#[U R Q X] = qnsolve("closed", N, QQ, V, Z);



S_client=0
S_network=0.0005
S_netthread=0.00000383047788057
S_worker=0.000899591827675

m_netthread=1
m_worker=8

P = [ 0 1 0 0 0;
      0 0 1 0 0;
      0 0 0 1 0;
      0 0 0 0 1;
      1 0 0 0 0];
V = qncsvisits(P);
QQ = { qnmknode("-/g/inf", S_client),
       qnmknode("-/g/inf", S_network),
       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
       qnmknode("m/m/m-fcfs", S_worker, m_worker),
       qnmknode("-/g/inf", S_network) };
       
N=10
Z=0

#[U R Q X] = qnsolve("closed", N, QQ, V, Z);


%S_client=0
%S_network=0.0006
%S_netthread=0.00000383047788057
%S_worker=0.000899591827675
%
%m_netthread=1
%m_worker=8
%
%P = [ 0 1 0 0 0;
%      0 0 1 0 0;
%      0 0 0 1 0;
%      0 0 0 0 1;
%      1 0 0 0 0];
%V = qncsvisits(P);
%QQ = { qnmknode("-/g/inf", S_client),
%       qnmknode("-/g/inf", S_network),
%       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
%       qnmknode("m/m/m-fcfs", S_worker, m_worker),
%       qnmknode("-/g/inf", S_network) };
%       
%N=30
%Z=0
%
%[U R Q X] = qnsolve("closed", N, QQ, V, Z);


S_client=0
S_network=0.0006
S_netthread=0.00000383047788057
S_worker=0.000899591827675

m_netthread=1
m_worker=8

P = [ 0 1 0 0 0;
      0 0 1 0 0;
      0 0 0 1 0;
      0 0 0 0 1;
      1 0 0 0 0];
V = qncsvisits(P);
QQ = { qnmknode("-/g/inf", S_client),
       qnmknode("-/g/inf", S_network),
       qnmknode("m/m/m-fcfs", S_netthread, m_netthread),
       qnmknode("m/m/m-fcfs", S_worker, m_worker),
       qnmknode("-/g/inf", S_network) };
       
N=84
Z=0.0023

[U R Q X] = qnsolve("closed", N, QQ, V, Z);

U
R
Q
X


