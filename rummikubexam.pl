nn(color_net,  [X], C, [black,blue,orange,red])          :: tile_color(X,C).
nn(number_net, [X], N, [1,10,11,12,13,2,3,4,5,6,7,8,9,0]) :: tile_number(X,N).

joker(X) :- tile_number(X, 0).

valid_set(A1, A2, A3) :-
    tile_number(A1, N),
    tile_number(A2, N),
    tile_number(A3, N),
    tile_color(A1, C1),
    tile_color(A2, C2),
    tile_color(A3, C3),
    C1 \= C2,
    C1 \= C3,
    C2 \= C3.

valid_set(A1, A2, A3) :-
    joker(A1),
    tile_number(A2, N), tile_number(A3, N),
    tile_color(A2, C2), tile_color(A3, C3),
    C2 \= C3.

valid_set(A1, A2, A3) :-
    joker(A2),
    tile_number(A1, N), tile_number(A3, N),
    tile_color(A1, C1), tile_color(A3, C3),
    C1 \= C3.

valid_set(A1, A2, A3) :-
    joker(A3),
    tile_number(A1, N), tile_number(A2, N),
    tile_color(A1, C1), tile_color(A2, C2),
    C1 \= C2.

valid_run(A1, A2, A3) :-
    tile_color(A1, C),
    tile_color(A2, C),
    tile_color(A3, C),
    tile_number(A1, N1),
    tile_number(A2, N2),
    tile_number(A3, N3),
    N2 is N1 + 1,
    N3 is N2 + 1.

valid_run(A1, A2, A3) :-
    joker(A1),
    tile_color(A2, C), tile_color(A3, C),
    tile_number(A2, N2), tile_number(A3, N3),
    N3 is N2 + 1.

valid_run(A1, A2, A3) :-
    joker(A2),
    tile_color(A1, C), tile_color(A3, C),
    tile_number(A1, N1), tile_number(A3, N3),
    N3 is N1 + 2.

valid_run(A1, A2, A3) :-
    joker(A3),
    tile_color(A1, C), tile_color(A2, C),
    tile_number(A1, N1), tile_number(A2, N2),
    N2 is N1 + 1.