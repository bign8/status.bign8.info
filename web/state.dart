enum State { UNKNOWN, GREEN, YELLOW, RED, LOADING }

String color(State s) {
  switch (s) {
    case State.GREEN:
      return "green";
    case State.YELLOW:
      return "yellow";
    case State.RED:
      return "red";
    default:
      return "gray";
  }
}

State code2state(int code) {
  if (200 <= code && code < 300) {
    return State.GREEN;
  } else if (code == 429) {
    return State.YELLOW;
  } else {
    return State.RED;
  }
}

String state2class(State s) {
  switch (s) {
    case State.UNKNOWN:
      return 'status-ignore';
    case State.GREEN:
      return 'status-ok';
    case State.YELLOW:
      return 'status-warn';
    case State.RED:
      return 'status-bad';
    case State.LOADING:
      return 'status-loading';
  }
}

State maxState(State a, State b) => a.index > b.index ? a : b;
