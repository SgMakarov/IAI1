:- (dynamic human/2, touchdown/2, orc/2).
:- (discontiguous  human/2, touchdown/2, orc/2).

% :-[input].

%--------------------------------------RANDOM SEARCH PART--------------------------------------
% although, some functions will be reused in other parts


%function used in random search to determine next turn
choose_random_turn(X, Y, Go, Thrown_before) :-
    Turns=[U, D, R, L, Throw], % in the beginning we assume all turns are possible
    Xr is X+1, %here we define all turns
    Xl is X-1,
    Yu is Y+1,
    Yd is Y-1,
    U=[X, Yu, false], %there are new direction and boolean that determines whether throw is performed
    D=[X, Yd, false],
    R=[Xr, Y, false],
    L=[Xl, Y, false],
    random_member(Throw,
                  
                  [ [0, 1, true],
                    [1, 1, true],
                    [1, 0, true],
                    [1, -1, true],
                    [0, -1, true],
                    [-1, -1, true],
                    [-1, 0, true],
                    [-1, 1, true]
                  ]), %randomly choose one of directions to throw
     %delete all turns that are not allowed by rules
    (   X=:=0
    ->  delete(Turns, L, T1)
    ;   T1=Turns
    ),
    (   Y=:=0
    ->  delete(T1, D, T2)
    ;   T2=T1
    ),
    (   X=:=19
    ->  delete(T2, R, T3)
    ;   T3=T2
    ),
    (   Y=:=19
    ->  delete(T3, U, T4)
    ;   T4=T3
    ),
    (   Thrown_before
    ->  delete(T4, Throw, T5)
    ;   T4=T5
    ),
    random_member(Go, T5) %store in go variable final answer, it may be either throw direction or new x and y
. 
% as we store found paths as strings so that it is easy to print them,
% this function easilly can help to add new turn to path. 
add_turn_to_string(Throw, X, Y, Path, Output) :-
    swritef(Output, '%w\n%w%w %w', [Path, Throw, X, Y]).

play_random(X, Y, Score, Output, Thrown_before, Current_path, Turns_left) :-
    (   touchdown(X, Y), %base case, if we are on touchdown just return path and score
        Output=Current_path,
        Turns_left is Score
    ;   not(orc(X, Y)), % we lose if step on orc
        Score>0,  % we lose if ran out of turns
        choose_random_turn(X,
                           Y,
                           [Nx, Ny, Thrown],
                           Thrown_before), % randomly choose one of possible turns
    % and then perform it. If it is throw - do throw, find new coordinates, add turn to our path and do recursive call
    % if it is not throw, we just check if next step is human so that we don't have to decrease score and do recursive call
        (   Thrown
        ->  throw(X,
                  Y,
                  Xnew,
                  Ynew,
                  Nx,
                  Ny),
            ScoreN is Score-1,
            add_turn_to_string("P ",
                               Xnew,
                               Ynew,
                               Current_path,
                               Current_pathN),
            play_random(Xnew,
                        Ynew,
                        ScoreN,
                        Output,
                        true,
                        Current_pathN,
                        Turns_left)
        ;   (   human(Nx, Ny)
            ->  NewScore is Score,
                Current_pathN=Current_path,
                add_turn_to_string("",
                                   Nx,
                                   Ny,
                                   Current_path,
                                   Current_pathN)
            ;   NewScore is Score-1,
                add_turn_to_string("",
                                   Nx,
                                   Ny,
                                   Current_path,
                                   Current_pathN)
            ),
            play_random(Nx,
                        Ny,
                        NewScore,
                        Output,
                        Thrown_before,
                        Current_pathN,
                        Turns_left)
        )
    ).
    

    
throw(X, Y, Xnew, Ynew, DirX, DirY) :- %here is just a recursive function to find new coordinates by given initial coordinates and direction of throw
    
    Xn is X+DirX, %find new coordinates
    Yn is Y+DirY,
    not(orc(Xn, Yn)),(
    (   human(Xn, Yn) % if it is human, return values
    ->  Xnew is Xn,
        Ynew is Yn
    ;   ( Xn>=0, %if no, check validity of coordinates and recursively perform check again
        Yn>=0,
        Xn=<19,
        Yn=<19
        ),
        
        throw(Xn, Yn, Xnew, Ynew, DirX, DirY))
    ).

play_randomN(Tries, Path, Path_cur, Best, Best_cur) :- % the function that execute random search N times and return best found score and path
    (   Tries=0
    ->  Path=Path_cur,
        Best is 100-Best_cur
    ; % base case of recursion
   TriesN is Tries-1, % decrease counter of plays left
        (   play_random(0, 0, 100, P, false, "", Score)% execute random search
        -> 
    %next line just check if found result better than previous and do recursive call
  (   Score>Best_cur
            ->  play_randomN(TriesN,
                             Path,
                             P,
                             Best,
                             Score)
            ;   play_randomN(TriesN,
                             Path,
                             Path_cur,
                             Best,
                             Best_cur)
            )
        ;   play_randomN(TriesN, Path, Path_cur, Best, Best_cur) % and this is for the case our random search failed
        )
    ).

% this predicate will be used as goal to check random search
random_entry_point :-
    get_time(T),
    stamp_date_time(T,
                    date(_,
                         _,
                         _,
                         _,
                         M,
                         S,
                         _,
                         _,
                         _),
                    'UTC'), % get timestamp and extract minutes and seconds from it 
    play_randomN(100, Path, "no try successful", Score, 0), % try random search 100 times, initial best score is 0
    get_time(T2),
    stamp_date_time(T2,
                    date(_,
                         _,
                         _,
                         _,
                         M2,
                         S2,
                         _,
                         _,
                         _),
                    'UTC'),
    Min is M2-M, % get difference between first and second time
    Sec is S2-S,
    ( write(Score),
      nl,
      write(Path),
      nl
    ), %print score and path if found
    writef("%wm%ws", [Min, Sec]),
    nl. % print time spent on random search 



%-------------------------------------BACKTRACKING PART--------------------------------------
:- (dynamic used/2, path/1, score/1, time/1).

backtrack_entry_point :-
    (   assert(path("no path")), % for the case path will not be found
        assert(score(10000)),    % if path will be found, it will definitely take less turns, so this will be updated
        get_time(T),
        assert(time(T)), %memorize time when started
        backtrack(0, 0, false, "", 0) )%call function for backtracking
   ;   score(Score),
        write(Score),
        nl,
        path(Path),
        write(Path),
        nl,
        time(T),
        stamp_date_time(T,
                        date(_,
                             _,
                             _,
                             _,
                             M,
                             S,
                             _,
                             _,
                             _),
                        'UTC'), % get timestamp and extract minutes and seconds from it 
        get_time(T2),
        stamp_date_time(T2,
                        date(_,
                             _,
                             _,
                             _,
                             M2,
                             S2,
                             _,
                             _,
                             _),
                        'UTC'),
        Min is M2-M, % get difference between first and second time
        Sec is S2-S,
        writef("%wm%ws\n", [Min, Sec]),
        retractall(time),
        retractall(score),
        retractall(used),
        retractall(path)
    . 


backtrack(X, Y, Thrown_before, Current_path, Current_score) :-
    (score(Best), Best =< Current_score -> fail;true),(
    (   touchdown(X, Y), %if we are on touchdown, we check whether our path is shorter than before and if so retract old values and assert new
        score(Best), % get old best score
        
        (   Best>Current_score
        ->  retract(score(Best)),
            retract(path(_)),
            assert(score(Current_score)),
            assert(path(Current_path))
        ;   true
        ), %assert new if it is better
        false % because we want other path to be discovered, and there are OR's in backtracking, which are "lazy" in prolog, touchdown should evaluate to false 
    ;   not(used(X, Y)), %here are some conditions for our cell to be accessible
        X>=0,
        Y>=0,
        X=<19,
        Y=<19,
        not(orc(X, Y)),
        assert(used(X, Y)), % this assertion is for our recursion not to be infinite
        Xr is X+1,
        Xl is X-1,
        Yu is Y+1,
        Yd is Y-1,

    (   
        % first, let's try throws, if possible, as they can increase score, but if not succeed, take constant time to backtrack
  (   (   not(Thrown_before)
            ->  ScoreN is Current_score+1,
                (   throw(X, Y, Xnew, Ynew, 1, 1),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                ;   throw(X, Y, Xnew, Ynew, 0, 1),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                ;   throw(X, Y, Xnew, Ynew, 1, 0),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                ;   throw(X, Y, Xnew, Ynew, 1, -1),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                ;   throw(X, Y, Xnew, Ynew, -1, 1),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                ;   throw(X, Y, Xnew, Ynew, 0, -1),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                ;   throw(X, Y, Xnew, Ynew, -1, 0),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                ;   throw(X, Y, Xnew, Ynew, -1, -1),
                    add_turn_to_string("P ",
                                       Xnew,
                                       Ynew,
                                       Current_path,
                                       Current_pathN),
                    backtrack(Xnew, Ynew, true, Current_pathN, ScoreN)
                )
            ;   false
            )
        ;



        % after throws, do steps:
        % first go upwards:
   add_turn_to_string("", X, Yu, Current_path, Current_pathN),
            (   human(X, Yu)
            ->  ScoreN is Current_score
            ;   ScoreN is Current_score+1
            ),
            backtrack(X, Yu, Thrown_before, Current_pathN, ScoreN)
        ;
        % then to the right
   add_turn_to_string("", Xr, Y, Current_path, Current_pathN),
            (   human(Xr, Y)
            ->  ScoreN is Current_score
            ;   ScoreN is Current_score+1
            ),
            backtrack(Xr, Y, Thrown_before, Current_pathN, ScoreN)
        ;
        % down
   add_turn_to_string("", X, Yd, Current_path, Current_pathN),
            (   human(X, Yd)
            ->  ScoreN is Current_score
            ;   ScoreN is Current_score+1
            ),
            backtrack(X, Yd, Thrown_before, Current_pathN, ScoreN)
        ;
        % left
   add_turn_to_string("", Xl, Y, Current_path, Current_pathN),
            (   human(Xl, Y)
            ->  ScoreN is Current_score
            ;   ScoreN is Current_score+1
            ),
            backtrack(Xl, Y, Thrown_before, Current_pathN, ScoreN)
        ;   retract(used(X, Y)), %after checking all neighbours we can "free" our cell as there can be more optimal paths to it
            false %backtrack always should be evaluated as false by the reasons I described before, so this is needed
        )
    ))
    ).

%-------------------------------------BREADTH-FIRST SEARCH PART--------------------------------------
:- dynamic(path/3, queue/3, thrown/2, used/2).  %dynamic facts to store best path and score to cell, and do we need pass to reach cell
bfs_entry_point :-
    assert(path(0, 0, "")), % push to the queue 0,0
    assert(queue(0, 0, 0)),
   
    get_time(T),
    stamp_date_time(T,
                    date(_,
                            _,
                            _,
                            _,
                            M,
                            S,
                            _,
                            _,
                            _),
                    'UTC'), % get timestamp and extract minutes and seconds from it 
    bfs(Score, Path), % launch bfs
    get_time(T2),
    stamp_date_time(T2,
                    date(_,
                            _,
                            _,
                            _,
                            M2,
                            S2,
                            _,
                            _,
                            _),
                    'UTC'),
    Min is M2-M, % get difference between first and second time
    Sec is S2-S,
    write(Score),
    nl,
    write(Path),
    nl,
    %print score and path if found
    writef("%wm%ws", [Min, Sec]),
    nl.

find_min_in_queue(X, Y, Score) :-
    findall([Xx, Yy, Z],
          queue(Xx, Yy, Z),
          List),
    min_in_list(List, 0, 0, 1000, X, Y, Score).

min_in_list([], Xcur, Ycur, Score_cur, X, Y, Score) :-
    X is Xcur,
    Y is Ycur,
    Score is Score_cur.
min_in_list([[Xx, Yy, Scores]|T], Xcur, Ycur, Score_cur, X, Y, Score) :-
    (   Scores<Score_cur
    ->  min_in_list(T,
                    Xx,
                    Yy,
                    Scores,
                    X,
                    Y,
                    Score)
    ;   min_in_list(T,
                    Xcur,
                    Ycur,
                    Score_cur,
                    X,
                    Y,
                    Score)
    ).    
    
bfs(Output, Path) :-
    find_min_in_queue(X, Y, Score),
    retract(queue(X, Y, _)),
    assert(used(X, Y)),
    path(X, Y, Current_path),( %find next cell in queue and mark as visited
    (   touchdown(X, Y)
    ->  Output=Score,
        path(X, Y, Path)
    ; %if it is touchdown, return it
    %else we push all neighbours that are not visited and not in queue to the queue
    
    %first do throws, if didn't throw before. Check on visited and queue
   (not(orc(X, Y)),   X >= 0,
    Y >= 0,
    X =< 19,
    Y =< 19,not(thrown(X, Y))
        ->  ScoreN is Score+1,
            (   throw(X, Y, Xnew, Ynew, 1, 1), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   throw(X, Y, Xnew, Ynew, 0, 1), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   throw(X, Y, Xnew, Ynew, 1, 0), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   throw(X, Y, Xnew, Ynew, -1, 1), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   throw(X, Y, Xnew, Ynew, 1, -1), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   throw(X, Y, Xnew, Ynew, -1, 0), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   throw(X, Y, Xnew, Ynew, 0, -1), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   throw(X, Y, Xnew, Ynew, -1, -1), %obtain new coordinates
                not(used(Xnew, Ynew)), % check all conditions
                not(queue(Xnew, Ynew, _)),
                add_turn_to_string("P ",
                                   Xnew,
                                   Ynew,
                                   Current_path,
                                   Current_pathN),
                assert(queue(Xnew, Ynew, ScoreN)), %push to the queue, write path, write that throw is performed to reach this poing
                assert(path(Xnew, Ynew, Current_pathN)),
                assert(thrown(Xnew, Ynew)),
                false
            ;   true
            )
        ;   true
        ),
 %now we can process adjacent cells
        Xr is X+1, %here we define all turns
        Xl is X-1,
        Yu is Y+1,
        Yd is Y-1,
        % and here push obtained cells to the queue
        (X >= 0,
            Y >= 0,
            X =< 19,
            Y =< 19,  not(orc(X, Y)), add_turn_to_string("", X, Yu, Current_path, Current_pathN),
            (   human(X, Yu)
            ->  ScoreN is Score
            ;   ScoreN is Score+1
            ),
            assert(queue(X, Yu, ScoreN)),
            assert(path(X, Yu, Current_pathN)),
            false
        ;   add_turn_to_string("", Xr, Y, Current_path, Current_pathN),
            (   human(Xr, Y)
            ->  ScoreN is Score
            ;   ScoreN is Score+1
            ),
            assert(queue(Xr, Y, ScoreN)),
            assert(path(Xr, Y, Current_pathN)),
            false
        ;   add_turn_to_string("", X, Yd, Current_path, Current_pathN),
            (   human(X, Yd)
            ->  ScoreN is Score
            ;   ScoreN is Score+1
            ),
            assert(queue(X, Yd, ScoreN)),
            assert(path(X, Yd, Current_pathN)),
            false
        ;   add_turn_to_string("", Xl, Y, Current_path, Current_pathN),
            (   human(Xl, Y)
            ->  ScoreN is Score
            ;   ScoreN is Score+1
            ),
            assert(queue(Xl, Y, ScoreN)),
            assert(path(Xl, Y, Current_pathN)),
            false
        ;   true
        ),
        bfs(Output, Path) % recursive call, as we are not done until path is found
    )
).
