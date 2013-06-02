/**
   Copyright: © 2013 Simon Kérouack.

   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.

   Authors: Simon Kérouack
*/
module util.args;
import util.config;

alias void delegate(string, Config) ResolverDelegate;
alias void function(string, Config) ResolverFunction;

// Resolvers by regex.
ResolverDelegate[string] resolvers;

// TODO: make this a regex lexer.
// whenever an arg match a regex, call the related delegate.

void parseArgs(string[] args) {
}
