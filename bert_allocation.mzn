%Milan Schollier

%given
int: N; %how many ships
int: L;  % Total length of the quay
int: s;  % Maximum allowed shift for berthing time
int: d;  % Minimum safety distance between vessels
int: C; %how many cranes
int: r;  % Range of each quay crane
array[QC] of int: qcbasepositions;  % Base positions of quay cranes
array[V] of int: lengths;  % Length of each vessel
array[V] of int: arrivaltimes;  % Scheduled start time of each vessel
array[V] of int: departuretimes;  % Scheduled end time of each vessel
array[V] of int: minimumnumqcs;  % Minimum number of quay cranes required for each vessel

%sets
set of int: QC=1..C;  % Set of quay cranes
set of int: V= 1..N;  % Set of vessels

% Decision variables
array[V] of var 0..L: Ai;  % Berth position for each vessel
array[V] of var 0..24*7: Si;  % Shifted start time for each vessel
array[V] of var 0..24*7: Ei;  % Shifted end time for each vessel
array[V, QC] of var bool: QC_assigned;  % QC assignment to each vessel

% 1. Ensure that each vessel is fully moored within the quay
constraint forall(i in V) (
    Ai[i] + lengths[i] <= L
);

% 2. Ensure that vessels do not overlap in space and time, considering safety distance
constraint forall(i, j in V where i < j) (
    %time
    (
      (Si[i]>Ei[i] xor Si[j]>Ei[j])%if both loop also time overlap
      /\
      Si[j]>Ei[i] /\ Si[i]>Ei[j]%makes a train both starts are before others endif
    ) 
    \/ 
    (  %if no loops, start j after end i or vice versa
      (Si[i]<=Ei[i] /\ Si[j]<=Ei[j]) 
      /\ 
      (Si[j]>Ei[i] \/ Si[i]>Ei[j])
    ) 
    %space
    \/
    (Ai[i] + lengths[i] + d <= Ai[j] \/ Ai[j] + lengths[j] + d <= Ai[i])  % No space overlap with safety distance
);

% 3. Loop around still same length
constraint forall(i in V) (
    Ei[i]=(Si[i]+ (departuretimes[i] - arrivaltimes[i]))mod(24*7) % Ensure duration remains the same
);
% 4. max shift
constraint forall(i in V) (
    Si[i]<= arrivaltimes[i]+s /\ Si[i]>=arrivaltimes[i] % Ensure duration remains the same
);

% 5. QC compatibility and minimum QC requirements for each vessel
constraint forall(v in V) (
    sum([QC_assigned[v, c] | c in QC]) >= minimumnumqcs[v] /\
    forall(c in QC) (
        QC_assigned[c, v] = 1 ->
        (qcbasepositions[c] <= Ai[v] /\ Ai[v] + lengths[v] <= qcbasepositions[c] + r)
    )
);

%6. crane can only serve one ship at a time
constraint forall(c in QC, i, j in V where i < j) (
    QC_assigned[i, c] + QC_assigned[j, c] <= 1   % Crane c cannot serve both i and j
    \/% or their times do not overlap
    %time
    (
      (Si[i]>Ei[i] xor Si[j]>Ei[j])%if both loop also time overlap
      /\
      Si[j]>Ei[i] /\ Si[i]>Ei[j]%makes a train both starts are before others endif
    ) 
    \/ 
    (  %if no loops, start j after end i or vice versa
      (Si[i]<=Ei[i] /\ Si[j]<=Ei[j]) 
      /\ 
      (Si[j]>Ei[i] \/ Si[i]>Ei[j])
    )
);

solve satisfy;

output [
    "\(v):\(Ai[v])-\(Ai[v]+lengths[v]);\(Si[v])..\(Ei[v]);" ++  (join(",", [show(c) | c in QC where fix(QC_assigned[v, c] = 1)])) ++ "\n" | v in V
];
