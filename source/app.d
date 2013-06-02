/**
   Copyright: © 2013 Simon Kérouack.
   License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
   Authors: Simon Kérouack
*/
import core.daemon;

int main(string[] args) {
  auto daemon = new Daemon(args);
  return 0;
}
