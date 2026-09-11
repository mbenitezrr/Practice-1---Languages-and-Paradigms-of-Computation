/* Mateo Benítez Ramírez
====================================================================
 Universidad EAFIT - Languages and Paradigms of Computation
 2026-2 - First Practice - Part B: Logic paradigm (Prolog)
 
 University ID Card Code decoder.
 
 Design: the problem is modelled as a RELATION between an 8-digit
 code and its four characteristics (period, category, consecutive
 number, parity) - not as a function applied to an argument. The
 same predicate can therefore be used to obtain a description from
 a code, or to check whether a code and a candidate description
 agree with each other.
===================================================================== 
*/


/*
----------------------
 1. Format validation
----------------------
*/

%  True when Code is a positive integer with exactly eight digits.
valid_code_format(Code) :-
    integer(Code),
    Code >= 10000000,
    Code =< 99999999.

%  The admission periods covered by this activity: 2026-2 .. 2029-2.
valid_period(262).
valid_period(271).
valid_period(272).
valid_period(281).
valid_period(282).
valid_period(291).
valid_period(292).


/*
-----------------------------------------
 2. Arithmetic decomposition of the code
-----------------------------------------
*/


%  Splits an 8-digit code PPP-CC-NNN into its three numeric sections.
%  Example: decompose(26276002, 262, 76, 2).
decompose(Code, Period, Category, Consecutive) :-
    Period      is Code // 100000,
    Category    is (Code // 1000) mod 100,
    Consecutive is Code mod 1000.


/*
-------------------------------------------------------------
 3. Aliquot sum via non-deterministic generation + findall/3
-------------------------------------------------------------
*/
 
%  Non-deterministically produces, on backtracking, every proper
%  divisor of N (every D with 1 =< D < N such that D divides N).
proper_divisor(N, D) :-
    Max is N - 1,
    between(1, Max, D), %  "Try ever D between 1 and Max" The between makes this predicate non-deterministic.
    N mod D =:= 0.

%  Collects every proper divisor with findall/3, as required, then
%  adds them up. 
aliquot_sum(N, Sum) :-
    findall(D, proper_divisor(N, D), Divisors), %  The findall makes this predicate deterministic.
    sum_list(Divisors, Sum).


/*
---------------------------------------------------------------
 4. Nicomachus classification - three mutually exclusive rules
---------------------------------------------------------------
*/

%  Class is abundant, perfect or deficient depending on how the
%  aliquot sum of N compares with N. 
nicomachus(N, abundant)  :- aliquot_sum(N, S), S > N.
nicomachus(N, perfect)   :- aliquot_sum(N, S), S =:= N.
nicomachus(N, deficient) :- aliquot_sum(N, S), S < N.
%  Notice how abundant and deficient dont use "or equal", this makes each of the three
%  classes mutually exclusive so that theres no interferance.

%  Maps the 2-digit category code to the academic-program category,
%  through the Nicomachus classification (Following Table 1).
program_category(N, 'Administrative') :- nicomachus(N, abundant).
program_category(N, 'Engineering')    :- nicomachus(N, perfect).
program_category(N, 'Humanities')     :- nicomachus(N, deficient).


/*
-----------------------
 5. Formatting helpers
-----------------------
*/

%  262 -> '2026-2'
format_period(Period, Formatted) :-
    Year is Period // 10,
    Semester is Period mod 10,
    format(atom(Formatted), "20~w-~w", [Year, Semester]).
    
%  atom saves the result as a variable called Formatted for later use

%  2 -> num2
format_num(Consecutive, Formatted) :-
    format(atom(Formatted), "num~w", [Consecutive]).

%  Even/odd descriptor of the *whole* code, as the pdf asks.
code_parity(Code, even) :- Code mod 2 =:= 0.
code_parity(Code, odd)  :- Code mod 2 =:= 1.


/*
---------------------------------------------------------------
 6. Main predicate: relates a code to its four characteristics
---------------------------------------------------------------

  - Called with only Code bound: computes the four characteristics.
  - Called with everything bound: succeeds or fails depending on
    whether the description is correct, because Prolog just unifies the computed values
    against whatever was already bound.
  - Fails (rejects) whenever the code has the wrong number of
    digits or an out-of-range admission period.
    
*/

id_card(Code, Period, Category, Num, Parity) :-
    valid_code_format(Code),
    decompose(Code, PeriodDigits, CategoryDigits, ConsecutiveDigits),
    
    valid_period(PeriodDigits),
    format_period(PeriodDigits, Period),
    
    program_category(CategoryDigits, Category),
    format_num(ConsecutiveDigits, Num),
    
    code_parity(Code, Parity).

%  Convenience predicate: joins the four characteristics into the
%  single space-separated atom shown in the statement's table, e.g.
%  describe(26276002, '2026-2 Humanities num2 even').
describe(Code, Description) :-
    id_card(Code, Period, Category, Num, Parity),
    format(atom(Description), "~w ~w ~w ~w", [Period, Category, Num, Parity]).


/*
-----------------------------------------------------
% 7. "Generate" mode - reversibility of the relation
-----------------------------------------------------

  The inverse direction: instead of decomposing a known code, this
  CONSTRUCTS every code matching a period and a category, without
  any code known in advance. Demonstrates that id_card/5's building
  blocks are reversible relations, not one-way functions.
  Example: codes_for(292, 'Engineering', Codes).
 
 */
 
codes_for(Period, CategoryName, Codes) :-
    valid_period(Period),
    findall(Code,
            ( between(1, 99, CategoryDigits),
              program_category(CategoryDigits, CategoryName), % Verifies that the digits match with the academic program category
              between(1, 999, Consecutive),
              Code is Period * 100000 + CategoryDigits * 1000 + Consecutive
            ),
            Codes).

%  A smaller, easier-to-read generate-mode query: which 2-digit
%  category codes (1..99) belong to a given category?
category_digits_for(CategoryName, Digits) :-
    findall(D,
            ( between(1, 99, D), program_category(D, CategoryName) ),
            Digits).


/*
------------------------------------------------------------------------------------
 8. Interactive Loop (it keeps going until receiving an empty line or reaching EOF)
------------------------------------------------------------------------------------
*/

loop :-
    read_line_to_string(user_input, Line),
    (   Line \== end_of_file, Line \== ""
    ->  (   number_string(Code, Line), describe(Code, Description)
        ->  writeln(Description)
        ;   writeln('REJECTED (invalid format or period)')
        ),
        flush_output,
        loop  % Recursive call for next line
    ;   halt
    ).

main :-
    writeln('Enter 8-digit codes, one per line (empty line or EOF to stop):'),
    flush_output, %  Prints instantly instead of waiting for everything to print it all at once
    loop.

:- initialization(main).