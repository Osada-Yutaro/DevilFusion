% 合体に関する述語

% 必要なデータを外部ファイルから読み込む
init :-
    consult('Library/lib.pl'),
    open('Data/table.dat', read, Table),
    read_file(Table, Groups),
    close(Table),
    open('Data/devil.dat', read, Devils),
    read_file(Devils, DevilData),
    close(Devils),
    open('Data/special.dat', read, Special),
    read_file(Special, SpecialFusion),
    close(Special),
    open('Data/create_spilit.dat', read, CreateSpilit),
    read_file(CreateSpilit, CreateSpilits),
    close(CreateSpilit),
    open('Data/rank.dat', read, Rank),
    read_file(Rank, SpilitFusion),
    close(Rank),
    add_rule(Groups),
    add_devil(DevilData),
    add_special(SpecialFusion),
    add_create_spilit(CreateSpilits),
    add_spilit_fusion(SpilitFusion),
    !.

    read_file(Stream, []) :-
    at_end_of_stream(Stream).
    read_file(Stream, [X|L]) :-
    \+ at_end_of_stream(Stream),
    read(Stream, X),
    read_file(Stream, L).

% 悪魔合体の種族決定の規則を追加する
add_rule(end_of_file).
add_rule([end_of_file]).
add_rule([(X, Y, Z)|W]) :-
    add_rule(X, Y, Z),
    add_rule(W).
add_rule(X, Y, Z) :-
    assert(rule(X, Y, Z)).

% 悪魔の種族,名前,レベルを追加する
add_devil(end_of_file).
add_devil([end_of_file]).
add_devil([(X, Y, Z)|W]) :-
    add_devil(X, Y, Z),
    add_devil(W).
add_devil(Group, Devil, Level) :-
    assert(devil(Group, Devil, Level)).

% 特殊合体の悪魔を追加する
add_special(end_of_file).
add_special([end_of_file]).
add_special([(X)|Y]) :-
    add_special(X),
    add_special(Y).
add_special(Devil) :-
    assert(special(Devil)).

% 精霊の生成規則を追加する
add_create_spilit(end_of_file).
add_create_spilit([end_of_file]).
add_create_spilit([(X, Y)|Z]) :-
    add_create_spilit(X, Y),
    add_create_spilit(Z).
add_create_spilit(Group, Spilit) :-
    assert(create_spilit(Group, Spilit)).

% 精霊合体のランク変動を追加する
add_spilit_fusion(end_of_file).
add_spilit_fusion([end_of_file]).
add_spilit_fusion([(X, Y, Z)|W]) :-
    add_spilit_fusion(W),
    add_spilit_fusion(X, Y, Z).
add_spilit_fusion(Group, Spilit, Delta) :-
    assert(spilit_fusion(Group, Spilit, Delta)).

% 合体法則を双方向化
birule(X, Y, Z) :- rule(X, Y, Z).
birule(X, Y, Z) :- rule(Y, X, Z).

/*
    2体の悪魔のレベルを比較する
    devil_compare(d1, d2) は d1のレベル < d2のレベル のとき成功する
*/
devil_compare(Devil1, Devil2) :-
    devil(_, Devil1, Level1),
    devil(_, Devil2, Level2),
    Level1 < Level2.

% 悪魔をレベル順でソートする
devil_sort(List, Sorted) :-
    sort(devil_compare, List, Sorted).

% 悪魔をランクアップさせる.特殊合体悪魔はスキップする.
up_grade(Devil, UpDevil) :-
    devil(Group, Devil, Level),
    findall(X, (devil(Group, X, L), Level < L), Devils),
    exclude(special, Devils, NormalDevils),
    devil_sort(NormalDevils, [UpDevil|_]).
    
% 悪魔をランクダウンさせる.特殊合体悪魔はスキップする.
down_grade(Devil, UpDevil) :-
    devil(Group, Devil, Level),
    findall(X, (devil(Group, X, L), L < Level), Devils),
    exclude(special, Devils, NormalDevils),
    devil_sort(NormalDevils, SortedDevils),
    reverse(SortedDevils, [UpDevil|_]).

rank_change_(Devil, 0, Devil).
rank_change_(Devil, Delta, Devil1) :-
    0 < Delta,
    Delta1 is Delta - 1,
    up_grade(Devil, UpDevil),
    rank_change_(UpDevil, Delta1, Devil1),
    !.
rank_change_(Devil, Delta, Devil1) :-
    0 < Delta,
    Delta1 is Delta - 1,
    rank_change_(Devil, Delta1, Devil1),
    !.
rank_change_(Devil, Delta, Devil1) :-
    Delta < 0,
    Delta1 is Delta + 1,
    down_grade(Devil, DownDevil),
    rank_change_(DownDevil, Delta1, Devil1),
    !.
rank_change_(Devil, Delta, Devil1) :-
    Delta < 0,
    Delta1 is Delta + 1,
    rank_change_(Devil, Delta1, Devil1),
    !.

% ランクチェンジする
rank_change(Devil, Delta, ChangedDevil) :-
    0 < Delta,
    Delta1 is Delta - 1,
    up_grade(Devil, UpDevil),
    rank_change_(UpDevil, Delta1, ChangedDevil).
rank_change(Devil, Delta, ChangedDevil) :-
    Delta < 0,
    Delta1 is Delta + 1,
    down_grade(Devil, DownDevil),
    rank_change_(DownDevil, Delta1, ChangedDevil).

can_fusion(MaxLevelDevil, _, MaxLevelDevil).
can_fusion(_, MinLevel, Devil) :-
    devil(_, Devil, Level),
    Level2 is Level*2,
    MinLevel < Level2.

/*
    fusion(d1, d2, d3) は悪魔 d1, d2 を合体した時に作成される悪魔 d3 を求める
*/

% 精霊作成合体
fusion(Devil1, Devil2, Spilit) :-
    devil(Group, Devil1, _),
    devil(Group, Devil2, _),
    create_spilit(Group, Spilit),
    \+ Devil1 = Devil2.

% 精霊合体
fusion(Spilit, Devil1, Devil2) :-
    devil(Group, Devil1, _),
    spilit_fusion(Group, Spilit, Delta),
    rank_change(Devil1, Delta, Devil2).
fusion(Devil1, Spilit, Devil2) :-
    devil(Group, Devil1, _),
    spilit_fusion(Group, Spilit, Delta),
    rank_change(Devil1, Delta, Devil2).

% 普通の合体
fusion(Devil1, Devil2, Devil3) :-
    devil(Group1, Devil1, Level1),
    devil(Group2, Devil2, Level2),
    birule(Group1, Group2, Group3),
    findall(X, devil(Group3, X, _), Devils),
    exclude(special, Devils, DevilsExcludeSpecial),
    max_elem(devil_compare, DevilsExcludeSpecial, MaxLevelDevil),
    MinLevel is Level1 + Level2 + 1,
    include(can_fusion(MaxLevelDevil, MinLevel), DevilsExcludeSpecial, CanFusionDevils),
    min_elem(devil_compare, CanFusionDevils, Devil3).
