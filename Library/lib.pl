% 汎用述語

/* 
    大小比較述語 Compare, Compare によって大小比較が定義された要素のリストを受け取り最大となる要素を返す
    Compare(X, Y). は X < Y の時成功しそれ以外ならば失敗する述語
*/
max_elem(Compare, [X|Xs], Res) :- max_elem(Compare, Xs, X, Res),!.
max_elem(_, [], Beta, Beta).
max_elem(Compare, [X|Xs], Beta, Res) :-
    call(Compare, Beta, X),
    max_elem(Compare, Xs, X, Res),
    !.
max_elem(Compare, [_|Xs], Beta, Res) :- max_elem(Compare, Xs, Beta, Res),!.

/* 
    大小比較述語 Compare, Compare によって大小比較が定義された要素のリストを受け取り最小となる要素を返す
    Compare(X, Y). は X < Y の時成功しそれ以外ならば失敗する述語
*/
min_elem(Compare, [X|Xs], Res) :- min_elem(Compare, Xs, X, Res),!.
min_elem(_, [], Beta, Beta).
min_elem(Compare, [X|Xs], Beta, Res) :-
    call(Compare, X, Beta),
    min_elem(Compare, Xs, X, Res),
    !.
min_elem(Compare, [_|Xs], Beta, Res) :- min_elem(Compare, Xs, Beta, Res),!.

/*
    sort(Compare, List, Sorted) は大小比較述語 Compare と List を受け取って
    クイックソートされたリスト Sorted を返す
*/
sort(_, [], []).
sort(Compare, [X|List], Sorted) :-
    partition(Compare, List, X, List1, List2),
    sort(Compare, List1, Sorted1),
    sort(Compare, List2, Sorted2),
    append(Sorted1, [X|Sorted2], Sorted).

partition(_, [], _, [], []).
partition(Compare, [Y|List], X, [Y|List1], List2) :-
    call(Compare, Y, X),
    partition(Compare, List, X, List1, List2).
partition(Compare, [Y|List], X, List1, [Y|List2]) :-
    \+ call(Compare, Y, X),
    partition(Compare, List, X, List1, List2).
