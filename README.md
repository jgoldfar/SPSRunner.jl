# SPSRunner

[![Build Status](https://travis-ci.org/jgoldfar/SPSRunner.jl.svg?branch=master)](https://travis-ci.org/jgoldfar/SPSRunner.jl)

[![Coverage Status](https://coveralls.io/repos/jgoldfar/SPSRunner.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/jgoldfar/SPSRunner.jl?branch=master)

[![codecov.io](http://codecov.io/github/jgoldfar/SPSRunner.jl/coverage.svg?branch=master)](http://codecov.io/github/jgoldfar/SPSRunner.jl?branch=master)

SPSRunner.jl uses SPSBase.jl, JuMP, and Coin-OR packages to solve the scheduling problem.

Version: v1.0-pre

## Dependencies/Setup

* TeXLive (or at least BasicTeX) is required to build the documentation.

* This repository needs to be on your `JULIA_PKGDIR`.

* Note: On OSX, apparently CoinOptServices does not find the Homebrew-built libraries correctly, so they have to be built from source.

## Roadmap

### v2.0
* Build preferences and non-overlapping specialty soft constraints into functional calculation

## Who do I talk to? ##

* Jonathan Goldfarb (jgoldfar@my.fit.edu)