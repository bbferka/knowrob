%%
%% Copyright (C) 2014 by Moritz Tenorth
%%
%% This file contains tests for the spatial reasoning
%% tools in KnowRob.
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 3 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%

:- begin_tests(semantic_map_utils).

:- use_module(library('owl')).
:- use_module(library('owl_parser')).
:- use_module(library('comp_spatial')).
:- use_module(library('rdfs_computable')).
:- use_module(library('knowrob_objects')).
:- use_module(library('knowrob_perception')).

:- owl_parser:owl_parse('package://knowrob_map_data/owl/ccrl2_semantic_map.owl').
:- owl_parser:owl_parse('package://knowrob_srdl/owl/srdl2-comp.owl').

:- rdf_db:rdf_register_ns(xsd,      'http://www.w3.org/2001/XMLSchema#', [keep(true)]).
:- rdf_db:rdf_register_ns(knowrob,  'http://knowrob.org/kb/knowrob.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(test_map, 'http://knowrob.org/kb/test_comp_spatial.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(ias_map,  'http://knowrob.org/kb/ias_semantic_map.owl#', [keep(true)]).


test(map_instance) :-
  map_instance(ias_map:'SemanticEnvironmentMap0').
  

test(map_root_objects) :-
  map_root_objects(ias_map:'SemanticEnvironmentMap0', O),
  member('http://knowrob.org/kb/knowrob.owl#CounterTop205', O),
  length(O, 23),!.

  
test(map_root_object) :-
  map_root_object(ias_map:'SemanticEnvironmentMap0', knowrob:'CounterTop205'),!.

  
test(map_object_dimensions) :-
  map_object_dimensions(knowrob:'CounterTop205', 0.57500005, 2.0500002, 0.02),!.


test(map_child_object) :-
  map_child_object(knowrob:'Dishwasher37', knowrob:'Door40'),
  map_child_object(knowrob:'Dishwasher37', knowrob:'Handle145'),!.


test(map_child_objects) :-
  map_child_objects(knowrob:'Dishwasher37', Objects),
  member('http://knowrob.org/kb/knowrob.owl#Door40', Objects),
  member('http://knowrob.org/kb/knowrob.owl#Handle145', Objects),
  length(Objects, 2), !.


test(map_object_info) :-
  map_object_info(['http://knowrob.org/kb/knowrob.owl#CounterTop205',
                   'http://knowrob.org/kb/knowrob.owl#CounterTop',
                   [-0.08847681,-0.99607825,0.0,1.1006587,0.99607825,-0.08847681,0.0,0.54706275,0.0,0.0,1.0,0.84,0.0,0.0,0.0,1.0],
                   [2.0500002,0.57500005,0.02]]), !.

test(map_object_type) :-
  map_object_type('http://knowrob.org/kb/knowrob.owl#CounterTop205',
                   'http://knowrob.org/kb/knowrob.owl#CounterTop'),!.

test(map_object_label) :-
  map_object_label('http://knowrob.org/kb/knowrob.owl#CounterTop205', 'Counter'),!.



:- end_tests(semantic_map_utils).

