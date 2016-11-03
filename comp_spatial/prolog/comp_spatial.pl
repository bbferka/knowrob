/** <module> Predicates for spatial reasoning

  This module contains all computables that calculate qualitative spatial relations
  between objects to allow for spatial reasoning. In addition, there are computables
  to extract components of a matrix or position vector.

  Copyright (C) 2009-13 Moritz Tenorth, Lars Kunze
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
      * Neither the name of the <organization> nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@author Moritz Tenorth, Lars Kunze
@license BSD

*/
:- module(comp_spatial,
    [
      on_Physical/2,
      in_ContGeneric/2,
      comp_toTheRightOf/2,
      comp_toTheLeftOf/2,
      comp_toTheSideOf/2,
      comp_inFrontOf/2,
      comp_inCenterOf/2,
      comp_below_of/2,
      comp_above_of/2,
      comp_center/2,
      objectAtPoint2D/2,
      objectAtPoint2D/3
    ]).

:- use_module(library('semweb/rdfs')).
:- use_module(library('semweb/rdf_db')).
:- use_module(library('rdfs_computable')).
:- use_module(library('knowrob_objects')).
:- use_module(library('knowrob_temporal')).


:- rdf_db:rdf_register_ns(knowrob,      'http://knowrob.org/kb/knowrob.owl#',      [keep(true)]).
:- rdf_db:rdf_register_ns(comp_spatial, 'http://knowrob.org/kb/comp_spatial.owl#', [keep(true)]).



% define predicates as rdf_meta predicates
% (i.e. rdf namespaces are automatically expanded)
:-  rdf_meta
    on_Physical(r, r),
    on_Physical_at_time(r, r, +),
    in_ContGeneric(r, r),
    in_ContGeneric_at_time(r, r, +),
    comp_below_of(r,r),
    comp_below_of_at_time(r,r,+),
    comp_above_of(r,r),
    comp_above_of_at_time(r,r,+),
    comp_toTheSideOf(r, r),
    comp_toTheSideOf_at_time(r, r,+),
    comp_toTheRightOf(r, r),
    comp_toTheRightOf_at_time(r, r,+),
    comp_toTheLeftOf(r, r),
    comp_toTheLeftOf_at_time(r, r,+),
    comp_inFrontOf(r, r),
    comp_inFrontOf_at_time(r, r,+),
    comp_inCenterOf(r, r),
    comp_inCenterOf_at_time(r, r,+),
    comp_center(r, r).


spatially_holds_interval(S, P, O, I) :-
  var(I),
  call(P, S, O, I).
spatially_holds_interval(S, P, O, I) :-
  % I is a time instant
  nonvar(I),
  time_term(I, Instant),
  call(P, S, O, Instant).
spatially_holds_interval(S, P, O, I) :-
  % I is a closed interval
  nonvar(I),
  interval(I, [Begin, End]),
  spatially_holds_interval(S, P, O, Begin, End).
spatially_holds_interval(S, P, O, I) :-
  % I is an opened interval
  nonvar(I),
  interval(I, [Begin]),
  get_timepoint(End),
  spatially_holds_interval(S, P, O, Begin, End).
spatially_holds_interval(S, P, O, Begin, End) :-
  % NOTE: this is an approximation, just checking if the relations holds
  %       for begin and end of the time interval.
  %       This could be wrong if object poses change within this interval
  % TODO: ensure that this inference is correct by taking into account timepoints
  %       where the pose changed.
  call(P, S, O, Begin),
  call(P, S, O, End).


%% on_Physical(?Top, ?Bottom) is nondet.
%
% Check if Top is in the area of and above Bottom.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param Top Identifier of the upper Object
% @param Bottom Identifier of the lower Object
%
on_Physical(Top, Bottom) :-
    get_timepoint(Instant),
    on_Physical_at_time(Top, Bottom, Instant).
    
on_Physical_at_time(Top, Bottom, Instant) :-
    rdfs_individual_of(Top, knowrob:'SpatialThing-Localized'),
    % get object center for Top
    object_pose_at_time(Top, Instant, pose([TX,TY,TZ], _)),
    
    rdfs_individual_of(Bottom, knowrob:'SpatialThing-Localized'),
    Top \= Bottom,
    % query for objects at center point
    objectAtPoint2D(TX,TY,Bottom,Instant),
    % get height of objects at center point
    object_pose_at_time(Bottom, Instant, pose([_,_,BZ], _)),

    % the criterion is if the difference between them is less than epsilon=5cm
    <( BZ, TZ).

knowrob_temporal:holds(Top, 'http://knowrob.org/kb/knowrob.owl#on-Physical', Bottom, Interval) :-
    spatially_holds_interval(Top, on_Physical_at_time, Bottom, Interval).

%%% knowrob_temporal:holds(on_Physical(Top, Bottom), T) :-
%%%
%%%     object_detection(Top, T, VPT),
%%%     object_detection(Bottom, T, VPB),
%%%
%%%     rdf_triple(knowrob:eventOccursAt, VPT,    TopMatrix),
%%%     rdf_triple(knowrob:eventOccursAt, VPB, BottomMatrix),
%%%
%%%     rdf_triple(knowrob:m03, TopMatrix, literal(type(_,TCx))),atom_to_term(TCx,TX,_),
%%%     rdf_triple(knowrob:m13, TopMatrix, literal(type(_,TCy))),atom_to_term(TCy,TY,_),
%%%     rdf_triple(knowrob:m23, TopMatrix, literal(type(_,TCz))),atom_to_term(TCz,TZ,_),
%%%
%%%     rdf_triple(knowrob:m03, BottomMatrix, literal(type(_,BCx))),atom_to_term(BCx,BX,_),
%%%     rdf_triple(knowrob:m13, BottomMatrix, literal(type(_,BCy))),atom_to_term(BCy,BY,_),
%%%     rdf_triple(knowrob:m23, BottomMatrix, literal(type(_,BCz))),atom_to_term(BCz,BZ,_),
%%%
%%%     % read the dimensions of the bottom entity
%%%     rdf_triple(knowrob:widthOfObject, Bottom, literal(type(_,Bw))),atom_to_term(Bw,BW,_),
%%%     rdf_triple(knowrob:depthOfObject, Bottom, literal(type(_,Bd))),atom_to_term(Bd,BD,_),
%%%
%%%     % the criterion is if the difference between them is less than epsilon=5cm
%%%     =<( BZ, TZ ),
%%%
%%%     % additional criterion: center of the top entity has to be inside the
%%%     % area of the bottom entity
%%%     =<( (BX - 0.5*BD), TX ), >=( (BX + 0.5*BD), TX ),
%%%     =<( (BY - 0.5*BW), TY ), >=( (BY + 0.5*BW), TY ),
%%%     Top \= Bottom.




%% comp_above_of(?Top, ?Bottom) is nondet.
%
% Check if Top is in the area of and above Bottom.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param Top Identifier of the upper Object
% @param Bottom Identifier of the lower Object
%
comp_above_of(Top, Bottom) :-
    get_timepoint(Instant),
    comp_above_of_at_time(Top, Bottom, Instant).

comp_above_of_at_time(Top, Bottom, Instant) :-
    rdfs_individual_of(Top, knowrob:'SpatialThing-Localized'),
    
    % get object center for Top
    object_pose_at_time(Top, Instant, pose([TX,TY,TZ], _)),
    
    rdfs_individual_of(Bottom, knowrob:'SpatialThing-Localized'),
    Top \= Bottom,

    % query for objects at center point
    objectAtPoint2D(TX,TY,Bottom,Instant),

    % get height of objects at center point
    object_pose_at_time(Bottom, Instant, pose([_,_,BZ], _)),

    % the criterion is if the difference between them is less than epsilon=5cm
    <( BZ, TZ).

knowrob_temporal:holds(Top, 'http://knowrob.org/kb/knowrob.owl#above-Generally', Bottom, Interval) :-
    spatially_holds_interval(Top, comp_above_of_at_time, Bottom, Interval).


%% comp_below_of(?Bottom, ?Top) is nondet.
%
% Check if Top is in the area of and above Bottom.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param Bottom Identifier of the lower Object
% @param Top Identifier of the upper Object
%
comp_below_of(Bottom, Top) :- comp_above_of(Top, Bottom).

knowrob_temporal:holds(Bottom, 'http://knowrob.org/kb/knowrob.owl#below-Generally', Top, Interval) :-
    spatially_holds_interval(Top, comp_above_of_at_time, Bottom, Interval).


%% comp_toTheLeftOf(?Left, ?Right) is nondet.
%
% Check if Left is to the left of Right.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param Left Identifier of the left Object
% @param Right Identifier of the right Object
%
comp_toTheLeftOf(Left, Right) :-
    get_timepoint(Instant),
    comp_toTheLeftOf_at_time(Left, Right, Instant).

comp_toTheLeftOf_at_time(Left, Right, Instant) :-
    %
    % TODO: adapt this to take rotations and object dimensions into account
    %
    rdfs_individual_of(Left, knowrob:'SpatialThing-Localized'),
    object_pose_at_time(Left, Instant, pose([LX,LY,LZ], _)),
    
    rdfs_individual_of(Right, knowrob:'SpatialThing-Localized'),
    Left \= Right,
    object_pose_at_time(Right, Instant, pose([RX,RY,RZ], _)),

    =<( abs( LX - RX), 0.30),  % less than 30cm y diff
    =<( RY, LY ),              % right obj has a smaller y coord than the left one (on the table)
    =<( abs( LZ - RZ), 0.30).  % less than 30cm height diff

knowrob_temporal:holds(Left, 'http://knowrob.org/kb/knowrob.owl#toTheLeftOf', Right, Interval) :-
    spatially_holds_interval(Left, comp_toTheLeftOf_at_time, Right, Interval).


%% comp_toTheRightOf(?Right,?Left) is nondet.
%
% Check if Right is to the right of Left.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param Right Identifier of the right Object
% @param Left Identifier of the left Object
% @see comp_toTheLeftOf
%
comp_toTheRightOf(Right, Left) :- comp_toTheLeftOf(Left, Right).

knowrob_temporal:holds(Right, 'http://knowrob.org/kb/knowrob.owl#toTheRightOf', Left, Interval) :-
    spatially_holds_interval(Left, comp_toTheLeftOf_at_time, Right, Interval).


%% comp_toTheSideOf(?A, ?B) is nondet.
%
% Check if A is either to the left or the rigth of B.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param A Identifier of Object A
% @param B Identifier of Object B
% @see comp_toTheLeftOf
% @see comp_toTheRightOf
%
comp_toTheSideOf(A, B) :-
    once(comp_toTheRightOf(A, B); comp_toTheLeftOf(A, B)).

knowrob_temporal:holds(A, 'http://knowrob.org/kb/knowrob.owl#toTheSideOf', B, Interval) :-
    once(knowrob_temporal:holds(A, knowrob:'toTheRightOf', B, Interval) ;
         knowrob_temporal:holds(A, knowrob:'toTheLeftOf', B, Interval)).


%% comp_inFrontOf(?Front, ?Back) is nondet.
%
% Check if Front is in front of Back. Currently does not take the orientation
% into account, only the position and dimension.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param Front Identifier of the front Object
% @param Back Identifier of the back Object
%
comp_inFrontOf(Front, Back) :-
    get_timepoint(Instant),
    comp_inFrontOf_at_time(Front, Back, Instant).

comp_inFrontOf_at_time(Front, Back, Instant) :-
    %
    % TODO: adapt this to take rotations and object dimensions into account
    %
    rdfs_individual_of(Front, knowrob:'SpatialThing-Localized'),
    object_pose_at_time(Front, Instant, pose([FX,_,_], _)),
    
    rdfs_individual_of(Back, knowrob:'SpatialThing-Localized'),
    Front \= Back,
    object_pose_at_time(Back, Instant, pose([BX,_,_], _)),

    =<( BX, FX ).      % front obj has a higher x coord.
    
knowrob_temporal:holds(Front, 'http://knowrob.org/kb/knowrob.owl#inFrontOf-Generally', Back, Interval) :-
    spatially_holds_interval(Front, comp_inFrontOf_at_time, Back, Interval).


%% comp_inCenterOf(?Inner, ?Outer) is nondet.
%
% Check if Inner is in the center of OuterObj. Currently does not take the orientation
% into account, only the position and dimension.
%
% Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param Inner Identifier of the inner Object
% @param Outer Identifier of the outer Object
%
comp_inCenterOf(Inner, Outer) :-
    get_timepoint(Instant),
    comp_inCenterOf_at_time(Inner, Outer, Instant).

comp_inCenterOf_at_time(Inner, Outer, Instant) :-
    rdfs_individual_of(Inner, knowrob:'SpatialThing-Localized'),
    object_pose_at_time(Inner, Instant, pose([IX,IY,IZ], _)),
    
    rdfs_individual_of(Outer, knowrob:'SpatialThing-Localized'),
    Inner \= Outer,
    object_pose_at_time(Outer, Instant, pose([OX,OY,OZ], _)),

    =<( abs( IX - OX), 0.20),  % less than 20cm x diff
    =<( abs( IY - OY), 0.20),  % less than 20cm y diff
    =<( abs( IZ - OZ), 0.20).  % less than 20cm z diff
    
knowrob_temporal:holds(Inner, 'http://knowrob.org/kb/knowrob.owl#inCenterOf', Outer, Interval) :-
    spatially_holds_interval(Inner, comp_inCenterOf_at_time, Outer, Interval).


%% in_ContGeneric(?InnerObj, ?OuterObj) is nondet.
%
% Check if InnerObj is contained by OuterObj. Currently does not take the orientation
% into account, only the position and dimension.
%
                                % Implemented as a wrapper predicate around holds(...) that computes the relation for the
% current point in time
%
% @param InnerObj Identifier of the inner Object
% @param OuterObj Identifier of the outer Object
%
in_ContGeneric(InnerObj, OuterObj) :-
    get_timepoint(Instant),
    in_ContGeneric_at_time(InnerObj, OuterObj, Instant).

in_ContGeneric_at_time(InnerObj, OuterObj, Instant) :-
    rdfs_individual_of(InnerObj, knowrob:'EnduringThing-Localized'),
    object_pose_at_time(InnerObj, Instant, pose([IX,IY,IZ], _)),
    object_dimensions(InnerObj, ID, IW, IH),
    
    rdfs_individual_of(OuterObj, knowrob:'Container'),
    InnerObj \= OuterObj,
    object_pose_at_time(OuterObj, Instant, pose([OX,OY,OZ], _)),
    object_dimensions(OuterObj, OD, OW, OH),
    
    % InnerObj is contained by OuterObj if (center_i+0.5*dim_i)<=(center_o+0.5*dim_o)
    % for all dimensions (x, y, z)
    >=( (IX - 0.5*ID), (OX - 0.5*OD)-0.05), =<( (IX + 0.5*ID),  (OX + 0.5*OD)+0.05 ),
    >=( (IY - 0.5*IW), (OY - 0.5*OW)-0.05 ), =<( (IY + 0.5*IW), (OY + 0.5*OW)+0.05 ),
    >=( (IZ - 0.5*IH), (OZ - 0.5*OH)-0.05 ), =<( (IZ + 0.5*IH), (OZ + 0.5*OH)+0.05 ).

knowrob_temporal:holds(Inner, 'http://knowrob.org/kb/knowrob.owl#in-ContGeneric', Outer, Interval) :-
    spatially_holds_interval(Inner, in_ContGeneric_at_time, Outer, Interval).



% MT: tried to use matrix transformation library to perform easier computation of 'inside'
% using bounding box. Problem; does not work as long as not both objects are bound
%
% holds(in_ContGeneric(InnerObj, OuterObj), T) :-
%
%
% TODO: take time into account
%
%     nonvar(InnerObj), nonvar(OuterObj),
%     transform_relative_to(InnerObj, OuterObj, [_,_,_,IrelOX,_,_,_,IrelOY,_,_,_,IrelOZ,_,_,_,_]),
%
%     % read the dimensions of the outer entity
%     rdf_triple(knowrob:widthOfObject, OuterObj, LOW),strip_literal_type(LOW,Ow),atom_to_term(Ow,OW,_),
%     rdf_triple(knowrob:heightOfObject,OuterObj, LOH),strip_literal_type(LOH,Oh),atom_to_term(Oh,OH,_),
%     rdf_triple(knowrob:depthOfObject, OuterObj, LOD),strip_literal_type(LOD,Od),atom_to_term(Od,OD,_),
%
%
%     % is InnerInOuterCoordList inside bounding box of outer object?
%
%     >=( OD, IrelOX),
%     >=( OW, IrelOY),
%     >=( OH, IrelOZ),
%
%     InnerObj \= OuterObj.



% % % % % % % % % % % % % % % % % % % %
% matrix and vector computations (relating the homography-based
% position representation with the old center-point-based one)
%

%% comp_center(+Obj, ?Center) is semidet.
%
% Compute the center point of an object from its homography matrix
%
% @param Obj    The object identifier
% @param Center The center point identifier as a String 'translation_<rotation matrix identifier>'
comp_center(Obj, Center) :-
  rdf_triple(knowrob:orientation, Obj, Matrix),
  rdf_split_url(G, L, Matrix),
  atom_concat('translation_', L, P),
  rdf_split_url(G, P, Center).



      
%% objectAtPoint2D(+Point2D, ?Obj) is nondet.
%
% Compute which objects are positioned at the (x,y) coordinate of Point2D
%
% @param Point2D  Instance of a knowrob:Point2D for which the xCoord and yCoord can be computed
% @param Obj      Objects whose bounding boxes overlap this point in x,y direction
% 
objectAtPoint2D(Point2D, Obj) :-
    % get coordinates of point of interest
    rdf_triple(knowrob:xCoord, Point2D, PCxx), strip_literal_type(PCxx, PCx), atom_to_term(PCx,PX,_),
    rdf_triple(knowrob:yCoord, Point2D, PCyy), strip_literal_type(PCyy, PCy), atom_to_term(PCy,PY,_),
    objectAtPoint2D(PX,PY,Obj).

%
%

%% objectAtPoint2D(+PX, +PY, ?Obj) is nondet.
%
% Compute which objects are positioned at the given (x,y) coordinate 
%
% @param PX   X coordinate to be considered    
% @param PY   Y  coordinate to be considered
% @param Obj  Objects whose bounding boxes overlap this point in x,y direction
% @bug        THIS IS BROKEN FOR ALL NON-STANDARD ROTATIONS if the upper left matrix is partly zero
%
objectAtPoint2D(PX,PY,Obj) :-
    get_timepoint(Instant),
    objectAtPoint2D(PX,PY,Obj, Instant).
 
objectAtPoint2D(PX, PY, Obj, Instant) :-

    % get information of potential objects at positon point2d (x/y)
    object_dimensions(Obj, OD, OW, _),
    
    object_pose_at_time(Obj, Instant, mat([M00, M01, _, OX,
                                           M10, M11, _, OY,
                                           _, _, _, _,
                                           _, _, _, _])),

    % object must have an extension
    <(0,OW), <(0,OD),

    % calc corner points of rectangle (consider rectangular objects only!)
    P0X is (OX - 0.5*OW),
    P0Y is (OY + 0.5*OD),
    P1X is (OX + 0.5*OW),
    P1Y is (OY + 0.5*OD),
    P2X is (OX - 0.5*OW),
    P2Y is (OY - 0.5*OD),
    % rotate points
    RP0X is (OX + (P0X - OX) * M00 + (P0Y - OY) * M01),
    RP0Y is (OY + (P0X - OX) * M10 + (P0Y - OY) * M11),
    RP1X is (OX + (P1X - OX) * M00 + (P1Y - OY) * M01),
    RP1Y is (OY + (P1X - OX) * M10 + (P1Y - OY) * M11),
    RP2X is (OX + (P2X - OX) * M00 + (P2Y - OY) * M01),
    RP2Y is (OY + (P2X - OX) * M10 + (P2Y - OY) * M11),

    % debug: print rotated points
    %write('P0 X: '), write(P0X), write(' -> '), writeln(RP0X),
    %write('P0 Y: '), write(P0Y), write(' -> '), writeln(RP0Y),
    %write('P1 X: '), write(P1X), write(' -> '), writeln(RP1X),
    %write('P1 Y: '), write(P1Y), write(' -> '), writeln(RP1Y),
    %write('P2 X: '), write(P2X), write(' -> '), writeln(RP2X),
    %write('P2 Y: '), write(P2Y), write(' -> '), writeln(RP2Y),

    V1X is (RP1X - RP0X),
    V1Y is (RP1Y - RP0Y),

    V2X is (RP2X - RP0X),
    V2Y is (RP2Y - RP0Y),

    VPX is (PX - RP0X),
    VPY is (PY - RP0Y),

    DOT1 is (VPX * V1X + VPY * V1Y),
    DOT2 is (VPX * V2X + VPY * V2Y),
    DOTV1 is (V1X * V1X + V1Y * V1Y),
    DOTV2 is (V2X * V2X + V2Y * V2Y),

    =<(0,DOT1), =<(DOT1, DOTV1),
    =<(0,DOT2), =<(DOT2, DOTV2).


% compatibility with Prolog < 5.8
:- if(\+current_predicate(atomic_list_concat, _)).

  atomic_list_concat(List, Atom) :-
    concat_atom(List, Atom).

  atomic_list_concat(List, Separator, Atom) :-
    concat_atom(List, Separator, Atom).

:- endif.
