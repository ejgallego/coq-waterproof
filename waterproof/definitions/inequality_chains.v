(** * [inequality_chains.v]
Authors:
  - Jim Portegies
  - Jelle Wemmenhove
Creation date: 17 June 2021

A module to write and use chains of inequalities such as 
  (& 3 &<= 4 &< 7 &= 3 + 4 &< 8)  or
  (& 8 &> 3 + 4 &= 7 &> 4 &>= 3).
The combination of <- and > symbols in the same chain is syntactically valid, 
but the kernel does not know how their combination should be interpreted.
When used in a proof, this results in an error that informs the user about the missing interpretation,
the error can be hard to understand without knowle3dge of the underlying implementation.

We use type classes to overload the chain link symbols like '&=' and '&<'.

--------------------------------------------------------------------------------

This file is part of Waterproof-lib.

Waterproof-lib is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Waterproof-lib is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Waterproof-lib.  If not, see <https://www.gnu.org/licenses/>.
*)

(* Abstract representations for <, ≤, > and ≥ symbols.*)
Inductive LessRel :=
| rel_lt
| rel_le.
Inductive GreaterRel :=
| rel_gt
| rel_ge.

(* Types of chains. *)
(* Only contains =-relations. *)
Inductive EqualChain (T : Type) := 
| ec_base : T -> T -> EqualChain T (* first link *)
| ec_link : EqualChain T -> T -> EqualChain T. (* link another term to chain *)
(* Contains at least one <- or ≤-symbol. *)
Inductive LessChain (T : Type) :=
| lc_base : T -> LessRel -> T -> LessChain T (* first link *)
| lc_link1 : EqualChain T -> LessRel -> T -> LessChain T (* link < or ≤ and term to equality chain *)
| lc_link2 : LessChain T -> T -> LessChain T (* link term to chain with =-relation*)
| lc_link3 : LessChain T -> LessRel -> T -> LessChain T. (* link term to chain with <- or ≤-relation*)
(* Contains at least one >- or ≥-symbol. *)
Inductive GreaterChain (T : Type) :=
| gc_base : T -> GreaterRel -> T -> GreaterChain T (* first link *)
| gc_link1 : EqualChain T -> GreaterRel -> T -> GreaterChain T (* link > or ≥ and term to equality chain *)
| gc_link2 : GreaterChain T -> T -> GreaterChain T (* link term to chain with =-relation*)
| gc_link3 : GreaterChain T -> GreaterRel -> T -> GreaterChain T. (* link term to chain with >- or ≥-relation*)


(* Type classes for linking new terms to chains.
   Type classes are used for notation overloading of link symbols like '&=' *)
Class EqLink (A B C: Type) := eq_link : A -> B -> C. (*notation: _ &= _ *)
#[export] Instance eq_base (T : Type) : EqLink T T (EqualChain T) := ec_base T.
#[export] Instance ec_eq_link (T : Type) : EqLink (EqualChain T) T (EqualChain T) := ec_link T.
#[export] Instance lc_eq_link (T : Type) : EqLink (LessChain T) T (LessChain T) := lc_link2 T.
#[export] Instance gc_eq_link (T : Type) : EqLink (GreaterChain T) T (GreaterChain T) := gc_link2 T.

Class LtLink (A B C : Type) := lt_link : A -> B -> C. (*notation: _ &< _ *)
#[export] Instance lt_base (T : Type) : LtLink  T T (LessChain T) := 
  fun x => lc_base T x rel_lt.
#[export] Instance ec_lt_link (T : Type) : LtLink (EqualChain T) T (LessChain T) :=
  fun c1 => lc_link1 T c1 rel_lt.
#[export] Instance lc_lt_link (T : Type) : LtLink (LessChain T) T (LessChain T) := 
  fun c1 => lc_link3 T c1 rel_lt.

Class LeLink (A B C : Type) := le_link : A -> B -> C. (*notation: _ &≤ _ *)
#[export] Instance le_base (T : Type) : LeLink T T (LessChain T) := 
  fun x => lc_base T x rel_le.
#[export] Instance ec_le_link (T : Type) : LeLink (EqualChain T) T (LessChain T) := 
  fun c1 => lc_link1 T c1 rel_le.
#[export] Instance lc_le_link (T : Type) : LeLink (LessChain T) T (LessChain T) := 
  fun c1 => lc_link3 T c1 rel_le.

Class GtLink (A B C : Type) := gt_link : A -> B -> C. (*notation: _ &> _ *)
#[export] Instance gt_base (T : Type) : GtLink  T T (GreaterChain T) := 
  fun x => gc_base T x rel_gt.
#[export] Instance ec_gt_link (T : Type) : GtLink (EqualChain T) T (GreaterChain T) :=
  fun c1 => gc_link1 T c1 rel_gt.
#[export] Instance gc_gt_link (T : Type) : GtLink (GreaterChain T) T (GreaterChain T) := 
  fun c1 => gc_link3 T c1 rel_gt.

Class GeLink (A B C : Type) := ge_link : A -> B -> C. (*notation: _ &≥ _ *)
#[export] Instance ge_base (T : Type) : GeLink T T (GreaterChain T) := 
  fun x => gc_base T x rel_ge.
#[export] Instance ec_ge_link (T : Type) : GeLink (EqualChain T) T (GreaterChain T) := 
  fun c1 => gc_link1 T c1 rel_ge.
#[export] Instance gc_ge_link (T : Type) : GeLink (GreaterChain T) T (GreaterChain T) := 
  fun c1 => gc_link3 T c1 rel_ge.


(* Chains contain multiple meanings:
    the global statement of (0 < 1 <= 2) is (0 < 2),
    the weak global statement            is (0 <= 2),
    the total statement                  is (0 < 1 /\ 1 <= 2)

   Again a type class is used such that we can use the same terms and notations
    for all three types of chains. *)
Class InterpretableChain (T : Type) (C : Type -> Type) := 
  { global_statement : C T -> Prop
  ; weak_global_statement : C T -> Prop
  ; total_statement : C T -> Prop
  }.


(** Helper functions *)

(* Head: first term in a chain *)
Fixpoint ec_head {T : Type} (c : EqualChain T) : T :=
match c with
| ec_base _ x y => x
| ec_link _ ec z => ec_head ec
end.
Fixpoint lc_head {T : Type} (c : LessChain T) : T :=
match c with
| lc_base _ x rel y => x
| lc_link1 _ ec rel z => ec_head ec
| lc_link2 _ lc z => lc_head lc
| lc_link3 _ lc rel z => lc_head lc
end.
Fixpoint gc_head {T : Type} (c : GreaterChain T) : T :=
match c with
| gc_base _ x rel y => x
| gc_link1 _ ec rel z => ec_head ec
| gc_link2 _ gc z => gc_head gc
| gc_link3 _ gc rel z => gc_head gc
end.

(* Tail: last term in a chain *)
Definition ec_tail {T : Type} (c : EqualChain T) : T :=
match c with
| ec_base _ x y => y
| ec_link _ ec z => z
end.
Definition lc_tail {T : Type} (c : LessChain T) : T :=
match c with
| lc_base _ x rel y => y
| lc_link1 _ ec rel z => z
| lc_link2 _ lc z => z
| lc_link3 _ lc rel z => z
end.
Definition gc_tail {T : Type} (c : GreaterChain T) : T :=
match c with
| gc_base  _ x rel y => y
| gc_link1 _ ec rel z => z
| gc_link2 _ lc z => z
| gc_link3 _ lc rel z => z
end.

(** Global & total statement - EqualChain *)
Definition ec_global_statement (T : Type) (c : EqualChain T) : Prop :=
  ec_head c = ec_tail c.
Fixpoint ec_total_statement (T : Type) (c : EqualChain T) : Prop :=
match c with
| ec_base _ x y => (x = y)
| ec_link _ c1 z => (ec_total_statement _ c1) /\ (ec_tail c1 = z)
end.
#[export] Instance ec_interpretable (T : Type) : InterpretableChain T EqualChain :=
  { global_statement := ec_global_statement T
  ; weak_global_statement := ec_global_statement T
  ; total_statement := ec_total_statement T
  }.

(** Helper functions specific to Less- and GreaterChain. *)
(* The global relation resulting from a combination of relations [rel1] and [rel2]. *)
Definition less_relation_flow (rel1 rel2 : LessRel) : LessRel :=
match rel1 with
| rel_lt => rel_lt
| rel_le => rel2
end.
Definition grtr_relation_flow (rel1 rel2 : GreaterRel) : GreaterRel :=
match rel1 with
| rel_gt => rel_gt
| rel_ge => rel2
end.
(* Returns the global relation of a LessChain. *)
Fixpoint global_less_rel {T : Type} (c : LessChain T) : LessRel :=
match c with
| lc_base _ x rel y => rel
| lc_link1 _ ec rel z => rel
| lc_link2 _ lc z => global_less_rel lc
| lc_link3 _ lc rel z => less_relation_flow (global_less_rel lc) rel
end.
(* Returns the global relation of a GreaterChain. *)
Fixpoint global_grtr_rel {T : Type} (c : GreaterChain T) : GreaterRel :=
match c with
| gc_base _ x rel y => rel
| gc_link1 _ ec rel z => rel
| gc_link2 _ gc z => global_grtr_rel gc
| gc_link3 _ gc rel z => grtr_relation_flow (global_grtr_rel gc) rel
end.

(* Functions to turn the abstract [LessRel] and [GreaterRel] relations into their concrete interpretations.
   We again use type classes to be able to use the same name for these fucntions across types that implement them.
  *)
Class LessRelInterpretation (T : Type) := less_rel_to_pred : LessRel -> T -> T -> Prop.
Class GreaterRelInterpretation (T : Type) := grtr_rel_to_pred : GreaterRel -> T -> T -> Prop.

(** Global & total statement - LessChain *)
Definition lc_global_statement (T : Type) `{! LessRelInterpretation T} (c : LessChain T) : Prop :=
less_rel_to_pred (global_less_rel c) (lc_head c) (lc_tail c).
Definition lc_weak_global_statement (T : Type) `{! LessRelInterpretation T} (c : LessChain T) : Prop :=
less_rel_to_pred rel_le (lc_head c) (lc_tail c).
Fixpoint lc_total_statement (T : Type) `{! LessRelInterpretation T} (c : LessChain T) : Prop :=
match c with
| lc_base _ x rel y => less_rel_to_pred rel x y
| lc_link1 _ ec rel z => (ec_total_statement _ ec) /\ less_rel_to_pred rel (ec_tail ec) z
| lc_link2 _ lc z => (lc_total_statement _ lc) /\ (lc_tail lc = z)
| lc_link3 _ lc rel z => (lc_total_statement _ lc) /\ less_rel_to_pred rel (lc_tail lc) z
end.
#[export] Instance lc_interpretable (T : Type) `{! LessRelInterpretation T} : InterpretableChain T LessChain :=
  { global_statement := lc_global_statement T
  ; weak_global_statement := lc_weak_global_statement T
  ; total_statement := lc_total_statement T
  }.

(** Global & total statement - GreaterChain *)
Definition gc_global_statement (T : Type) `{! GreaterRelInterpretation T} (c : GreaterChain T) : Prop :=
grtr_rel_to_pred (global_grtr_rel c) (gc_head c) (gc_tail c).
Definition gc_weak_global_statement (T : Type) `{! GreaterRelInterpretation T} (c : GreaterChain T) : Prop :=
grtr_rel_to_pred rel_ge (gc_head c) (gc_tail c).
Fixpoint gc_total_statement (T : Type) `{! GreaterRelInterpretation T} (c : GreaterChain T) : Prop :=
match c with
| gc_base _ x rel y => grtr_rel_to_pred rel x y
| gc_link1 _ ec rel z => (ec_total_statement _ ec) /\ grtr_rel_to_pred rel (ec_tail ec) z
| gc_link2 _ gc z => (gc_total_statement _ gc) /\ (gc_tail gc = z)
| gc_link3 _ gc rel z => (gc_total_statement _ gc) /\ grtr_rel_to_pred rel (gc_tail gc) z
end.
#[export] Instance gc_interpretable (T : Type) `{! GreaterRelInterpretation T} : InterpretableChain T GreaterChain :=
  { global_statement := gc_global_statement T
  ; weak_global_statement := gc_weak_global_statement T
  ; total_statement := gc_total_statement T
  }.

(* Notations for link type classes *)
Notation "c &= y" := (eq_link c y) (at level 71, left associativity).
Notation "c &< y" := (lt_link c y) (at level 71, left associativity).
Notation "c &<= y" := (le_link c y) (at level 71, left associativity).
Notation "c &≤ y" := (le_link c y) (at level 71, left associativity).
Notation "c &> y" := (gt_link c y) (at level 71, left associativity).
Notation "c &>= y" := (ge_link c y) (at level 71, left associativity).
Notation "c &≥ y" := (ge_link c y) (at level 71, left associativity).
Notation "& c" := (total_statement c) (at level 98).

(* Interpretations of [LessRel] and [GreaterRel] for the naturals. *)
#[export] Instance nat_less_rel_pred : LessRelInterpretation nat := 
  { less_rel_to_pred rel x y := match rel with | rel_lt => (x < y) | rel_le => (x <= y) end }.
#[export] Instance nat_grtr_rel_pred : GreaterRelInterpretation nat := 
  { grtr_rel_to_pred rel x y := match rel with | rel_gt => (x > y) | rel_ge => (x >= y) end }.

(* Interpretations of [LessRel] and [GreaterRel] for the reals. *)
Require Import Reals.
Open Scope R_scope.
#[export] Instance R_less_rel_pred : LessRelInterpretation R := 
  { less_rel_to_pred rel x y := match rel with | rel_lt => (x < y) | rel_le => (x <= y) end }.
#[export] Instance R_grtr_rel_pred : GreaterRelInterpretation R := 
  { grtr_rel_to_pred rel x y := match rel with | rel_gt => (x > y) | rel_ge => (x >= y) end }.
Close Scope R_scope.


(* Because the typeclasses used for the link-symbols '&=' are so general,
   they are unable to automatically make use of coercions,
   e.g. the chain (& INR 0 &= 1) is not accepted, Coq says it is unable to find
   an interpretation for (EqLink R nat ?C).

   We thus have to add all these cases manually.
*)

(* Helper functions: functorality of chain types. *)
Fixpoint ec_map {A B : Type} (f : A -> B) (c : EqualChain A) : EqualChain B :=
match c with 
| ec_base _ x y => ec_base _ (f x) (f y)
| ec_link _ ec z => ec_link _ (ec_map f ec) (f z)
end.
Fixpoint lc_map {A B : Type} (f : A -> B) (c : LessChain A) : LessChain B :=
match c with
| lc_base _ x rel y => lc_base _ (f x) rel (f y)
| lc_link1 _ ec rel z => lc_link1 _ (ec_map f ec) rel (f z)
| lc_link2 _ lc z => lc_link2 _ (lc_map f lc) (f z)
| lc_link3 _ lc rel z => lc_link3 _ (lc_map f lc) rel (f z)
end.
Fixpoint gc_map {A B : Type} (f : A -> B) (c : GreaterChain A) : GreaterChain B :=
match c with
| gc_base _ x rel y => gc_base _ (f x) rel (f y)
| gc_link1 _ ec rel z => gc_link1 _ (ec_map f ec) rel (f z)
| gc_link2 _ gc z => gc_link2 _ (gc_map f gc) (f z)
| gc_link3 _ gc rel z => gc_link3 _ (gc_map f gc) rel (f z)
end.

(* embedding INR : nat -> R *)
(* _ &= _ *)
#[export] Instance eq_base_nat_R : EqLink nat R (EqualChain R) := fun n x => ec_base R (INR n) x.
#[export] Instance eq_base_R_nat : EqLink R nat (EqualChain R) := fun x n => ec_base R x (INR n).
#[export] Instance ec_eq_link_nat_R : EqLink (EqualChain nat) R (EqualChain R) := 
  fun ecn x => ec_link R (ec_map INR ecn) x.
#[export] Instance ec_eq_link_R_nat : EqLink (EqualChain R) nat (EqualChain R) := 
  fun ecx n => ec_link R ecx (INR n).
#[export] Instance lc_eq_link_nat_R : EqLink (LessChain nat) R (LessChain R) := 
  fun lcn x => lc_link2 R (lc_map INR lcn) x.
#[export] Instance lc_eq_link_R_nat : EqLink (LessChain R) nat (LessChain R) := 
  fun lcx n => lc_link2 R lcx (INR n).
#[export] Instance gc_eq_link_nat_R : EqLink (GreaterChain nat) R (GreaterChain R) := 
  fun gcn x => gc_link2 R (gc_map INR gcn) x.
#[export] Instance gc_eq_link_R_nat : EqLink (GreaterChain R) nat (GreaterChain R) := 
  fun gcx n => gc_link2 R gcx (INR n).
(* _ &< _ *)
#[export] Instance lt_base_nat_R : LtLink nat R (LessChain R) := fun n x => lc_base R (INR n) rel_lt x.
#[export] Instance lt_base_R_nat : LtLink R nat (LessChain R) := fun x n => lc_base R x rel_lt (INR n).
#[export] Instance ec_lt_link_nat_R : LtLink (EqualChain nat) R (LessChain R) :=
  fun ecn => lc_link1 R (ec_map INR ecn) rel_lt.
#[export] Instance ec_lt_link_R_nat : LtLink (EqualChain R) nat (LessChain R) :=
  fun ecx n => lc_link1 R ecx rel_lt (INR n).
#[export] Instance lc_lt_link_nat_R : LtLink (LessChain nat) R (LessChain R) := 
  fun lcn => lc_link3 R (lc_map INR lcn) rel_lt.
#[export] Instance lc_lt_link_R_nat : LtLink (LessChain R) nat (LessChain R) := 
  fun lcx n => lc_link3 R lcx rel_lt (INR n).
(* _ ≤ _ *)
#[export] Instance le_base_nat_R : LeLink nat R (LessChain R) := fun n => lc_base R (INR n) rel_le.
#[export] Instance le_base_R_nat : LeLink R nat (LessChain R) := fun x n => lc_base R x rel_le (INR n).
#[export] Instance ec_le_link_nat_R : LeLink (EqualChain nat) R (LessChain R) := 
  fun ecn => lc_link1 R (ec_map INR ecn) rel_le.
#[export] Instance ec_le_link_R_nat : LeLink (EqualChain R) nat (LessChain R) := 
  fun ecx n => lc_link1 R ecx rel_le (INR n).
#[export] Instance lc_le_link_nat_R : LeLink (LessChain nat) R (LessChain R) := 
  fun lcn => lc_link3 R (lc_map INR lcn) rel_le.
#[export] Instance lc_le_link_R_nat : LeLink (LessChain R) nat (LessChain R) := 
  fun lcx n => lc_link3 R lcx rel_le (INR n).
(* _ > _ *)
#[export] Instance gt_base_nat_R : GtLink nat R (GreaterChain R) :=  fun n => gc_base R (INR n) rel_gt.
#[export] Instance gt_base_R_nat : GtLink R nat (GreaterChain R) :=  fun x n => gc_base R x rel_gt (INR n).
#[export] Instance ec_gt_link_nat_R : GtLink (EqualChain nat) R (GreaterChain R) :=
  fun ecn => gc_link1 R (ec_map INR ecn) rel_gt.
#[export] Instance ec_gt_link_R_nat : GtLink (EqualChain R) nat (GreaterChain R) :=
  fun ecx n => gc_link1 R ecx rel_gt (INR n).
#[export] Instance gc_gt_link_nat_R : GtLink (GreaterChain nat) R (GreaterChain R) := 
  fun gcn => gc_link3 R (gc_map INR gcn) rel_gt.
#[export] Instance gc_gt_link_R_nat : GtLink (GreaterChain R) nat (GreaterChain R) := 
  fun gcx n => gc_link3 R gcx rel_gt (INR n).
(* _ ≥ _ *)
#[export] Instance ge_base_nat_R : GeLink nat R (GreaterChain R) := fun n => gc_base R (INR n) rel_ge.
#[export] Instance ge_base_R_nat : GeLink R nat (GreaterChain R) := fun x n => gc_base R x rel_ge (INR n).
#[export] Instance ec_ge_link_nat_R : GeLink (EqualChain nat) R (GreaterChain R) := 
  fun ecn => gc_link1 R (ec_map INR ecn) rel_ge.
#[export] Instance ec_ge_link_R_nat : GeLink (EqualChain R) nat (GreaterChain R) := 
  fun ecx n => gc_link1 R ecx rel_ge (INR n).
#[export] Instance gc_ge_link_nat_R : GeLink (GreaterChain nat) R (GreaterChain R) := 
  fun gcn => gc_link3 R (gc_map INR gcn) rel_ge.
#[export] Instance gc_ge_link_R_nat : GeLink (GreaterChain R) nat (GreaterChain R) := 
  fun gcx n => gc_link3 R gcx rel_ge (INR n).


(* embedding IZR : Z -> R *)
(* _ &= _ *)
#[export] Instance eq_base_Z_R : EqLink Z R (EqualChain R) := fun z x => ec_base R (IZR z) x.
#[export] Instance eq_base_R_Z : EqLink R Z (EqualChain R) := fun x z => ec_base R x (IZR z).
#[export] Instance ec_eq_link_Z_R : EqLink (EqualChain Z) R (EqualChain R) := 
  fun ecz x => ec_link R (ec_map IZR ecz) x.
#[export] Instance ec_eq_link_R_Z : EqLink (EqualChain R) Z (EqualChain R) := 
  fun ecx z => ec_link R ecx (IZR z).
#[export] Instance lc_eq_link_Z_R : EqLink (LessChain Z) R (LessChain R) := 
  fun lcz x => lc_link2 R (lc_map IZR lcz) x.
#[export] Instance lc_eq_link_R_Z : EqLink (LessChain R) Z (LessChain R) := 
  fun lcx z => lc_link2 R lcx (IZR z).
#[export] Instance gc_eq_link_Z_R : EqLink (GreaterChain Z) R (GreaterChain R) := 
  fun gcz x => gc_link2 R (gc_map IZR gcz) x.
#[export] Instance gc_eq_link_R_Z : EqLink (GreaterChain R) Z (GreaterChain R) := 
  fun gcx z => gc_link2 R gcx (IZR z).
(* _ &< _ *)
#[export] Instance lt_base_Z_R : LtLink Z R (LessChain R) := fun z x => lc_base R (IZR z) rel_lt x.
#[export] Instance lt_base_R_Z : LtLink R Z (LessChain R) := fun x z => lc_base R x rel_lt (IZR z).
#[export] Instance ec_lt_link_Z_R : LtLink (EqualChain Z) R (LessChain R) :=
  fun ecz => lc_link1 R (ec_map IZR ecz) rel_lt.
#[export] Instance ec_lt_link_R_Z : LtLink (EqualChain R) Z (LessChain R) :=
  fun ecx z => lc_link1 R ecx rel_lt (IZR z).
#[export] Instance lc_lt_link_Z_R : LtLink (LessChain Z) R (LessChain R) := 
  fun lcz => lc_link3 R (lc_map IZR lcz) rel_lt.
#[export] Instance lc_lt_link_R_Z : LtLink (LessChain R) Z (LessChain R) := 
  fun lcx z => lc_link3 R lcx rel_lt (IZR z).
(* _ ≤ _ *)
#[export] Instance le_base_Z_R : LeLink Z R (LessChain R) := fun z => lc_base R (IZR z) rel_le.
#[export] Instance le_base_R_Z : LeLink R Z (LessChain R) := fun x z => lc_base R x rel_le (IZR z).
#[export] Instance ec_le_link_Z_R : LeLink (EqualChain Z) R (LessChain R) := 
  fun ecz => lc_link1 R (ec_map IZR ecz) rel_le.
#[export] Instance ec_le_link_R_Z : LeLink (EqualChain R) Z (LessChain R) := 
  fun ecx z => lc_link1 R ecx rel_le (IZR z).
#[export] Instance lc_le_link_Z_R : LeLink (LessChain Z) R (LessChain R) := 
  fun lcz => lc_link3 R (lc_map IZR lcz) rel_le.
#[export] Instance lc_le_link_R_Z : LeLink (LessChain R) Z (LessChain R) := 
  fun lcx z => lc_link3 R lcx rel_le (IZR z).
(* _ > _ *)
#[export] Instance gt_base_Z_R : GtLink Z R (GreaterChain R) :=  fun z => gc_base R (IZR z) rel_gt.
#[export] Instance gt_base_R_Z : GtLink R Z (GreaterChain R) :=  fun x z => gc_base R x rel_gt (IZR z).
#[export] Instance ec_gt_link_Z_R : GtLink (EqualChain Z) R (GreaterChain R) :=
  fun ecz => gc_link1 R (ec_map IZR ecz) rel_gt.
#[export] Instance ec_gt_link_R_Z : GtLink (EqualChain R) Z (GreaterChain R) :=
  fun ecx z => gc_link1 R ecx rel_gt (IZR z).
#[export] Instance gc_gt_link_Z_R : GtLink (GreaterChain Z) R (GreaterChain R) := 
  fun gcz => gc_link3 R (gc_map IZR gcz) rel_gt.
#[export] Instance gc_gt_link_R_Z : GtLink (GreaterChain R) Z (GreaterChain R) := 
  fun gcx z => gc_link3 R gcx rel_gt (IZR z).
(* _ ≥ _ *)
#[export] Instance ge_base_Z_R : GeLink Z R (GreaterChain R) := fun z => gc_base R (IZR z) rel_ge.
#[export] Instance ge_base_R_Z : GeLink R Z (GreaterChain R) := fun x z => gc_base R x rel_ge (IZR z).
#[export] Instance ec_ge_link_Z_R : GeLink (EqualChain Z) R (GreaterChain R) := 
  fun ecz => gc_link1 R (ec_map IZR ecz) rel_ge.
#[export] Instance ec_ge_link_R_Z : GeLink (EqualChain R) Z (GreaterChain R) := 
  fun ecx z => gc_link1 R ecx rel_ge (IZR z).
#[export] Instance gc_ge_link_Z_R : GeLink (GreaterChain Z) R (GreaterChain R) := 
  fun gcz => gc_link3 R (gc_map IZR gcz) rel_ge.
#[export] Instance gc_ge_link_R_Z : GeLink (GreaterChain R) Z (GreaterChain R) := 
  fun gcx z => gc_link3 R gcx rel_ge (IZR z).
