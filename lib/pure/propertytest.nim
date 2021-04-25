#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## XXX: Once this is good enough move this into the stdlib, for now mature in
##      the compiler
## 
## :Author: Saem Ghani
##
## This module implements property based testing facilities.
## 
## Heavily inspired by the excellent
## [Fast Check library](https://github.com/dubzzz/fast-check).
## 
## Concepts:
## * predicate - a function which given a value indicates true or false
## * arbitrary - generator of arbitrary value for some set of values
## * property - a condition a value must hold to, given a predicate
## * run - test a single value against a property
## 
## Future directions:
## * properties with predefined examples -- not purely random
## * before and after run hooks for properties
## * support for multiple random number generators
## * distribution control
## * model based checking
## * async testing
## * shrinking

type
  PTFailure* = enum
    ## the result of a single run/predicate check
    ## XXX: likely to be changed to a variant to support, true/false/error+data
    ptFail,
    ptPreCondFail,
    ptPass

  RunId* = range[1..high(int)]
    ## sequential id of the run, starts from 1
  
  RunIdInternal = distinct uint
   ## separate from `RunId` to support 0 value, indicating non-specified
  
  Predicate*[T] = proc(s: T): PTFailure
    ## test function to see if a property holds
  
  Random* = object
    foo: int # XXX: complete me
  
  Arbitrary*[T] = object of RootObj
    ## arbitrary value generator for some type T
    mgenerate: proc(a: Arbitrary[T], mrng: Random): Shrinkable[T]
    #mfilter: proc(v: T): U # where U:T
  
  Shrinkable*[T] = object
    ## future support for shrinking
    some: T

  Property*[T] = object
    ## condition an arbitrary set of values must hold, given a predicate
    arb: Arbitrary[T]
    predicate: Predicate[T]

#-- Run Id

const noRunId = 0.RunId

proc isUnspecified(r: RunIdInternal): bool =
  ## used for default param handling
  result = r.uint == 0

#-- Arbitrary



#-- Property

proc newProperty*[T](arb: Arbitrary[T], p: Predicate) =
  result = Property(arb: arb, predicate: p)

proc generateAux[T](p: Property[T], mrng: Random,
                    r: RunIdInternal): Shrinkable[T] =
  result =
    if r.isUnspecified:
      p.arb.withBias(runIdToFrequency(runId)).generate(mrng)
    else:
      p.arb.generate(mrng)

proc generate*[T](p: Property[T], mrng: Random, runId: RunId): Shrinkable[T] =
  return generateAux(p, mrng, runId)

proc generate*[T](p: Property[T], mrng: Random): Shrinkable[T] =
  return generateAux(p, mrng, noRunId)

proc run*[T](p: Property[T], v: T): PTFailure =
  try:
    result = p.predicate(v)
  except:
    # XXX: do some exception related checking here, for now pass through
    raise getCurrentException()
  finally:
    # XXX: for hooks
    discard