/-
Copyright (c) 2021 Jannis Limperg. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jannis Limperg
-/

import Aesop
import Lean

open Lean
open Lean.Meta
open Lean.Elab.Tactic
open Aesop.RuleTac (applyForwardRule)

set_option aesop.check.all true

/-! # Unit tests for the MetaM tactic that implements forward rules -/

syntax (name := forward) &"forward" ident "[" ident* "]" : tactic

@[tactic forward]
def evalForward : Tactic
  | `(tactic| forward $t:ident [ $immediate:ident* ]) => do
    let t ← getLocalDeclFromUserName t.getId
    let immediate := immediate.map (·.getId)
    liftMetaTactic λ goal =>
      return [← applyForwardRule goal (mkFVar t.fvarId) immediate]
  | _ => unreachable!

-- Note: The hypothesis names generated by `applyForwardRule` are not supposed
-- to be stable (but they are supposed to be unique).
set_option tactic.hygienic false

example (rule : (a : α) → (b : β) → γ) (h₁ : α) (h₂ : β) : γ := by
  forward rule [a b]
  exact fwd

example {P Q R : α → Type} (rule : ∀ a (p : P a) (q : Q a), R a)
    (h₁ : P a) (h₁' : P a) (h₂ : Q a) (h₃ : P b) (h₄ : Q c) : R a := by
  forward rule [p q]
  exact fwd

example {P Q R : α → Type} (rule : ∀ a (p : P a) (q : Q a), R a)
    (h₁ : P a) (h₂ : P b) : (Q a → R a) × (Q b → R b) := by
  forward rule [p]
  exact (fwd, fwd_1)

/-! # End-to-end tests -/

example (a : α) (b : β) (r₁ : (a : α) → (b : β) → γ₁ ∧ γ₂) (r₂ : (a : α) → δ₁ ∧ δ₂) :
    γ₁ ∧ γ₂ ∧ δ₁ ∧ δ₂ := by
  aesop (add safe
    [r₁ (forward (immediate := [a, b])), r₂ (forward (immediate := [a]))])
