import { describe, expect, test } from "bun:test";
import { planTermination } from "../src/herdr";

describe("termination planning", () => {
  test("uses a foreground group that is separate from the shell", () => {
    expect(planTermination({
      pane_id: "w1:p1",
      shell_pid: 100,
      foreground_process_group_id: 200,
      foreground_processes: [],
    }, [])).toEqual({ kind: "process-group", id: 200 });
  });

  test("signals only verified agent processes when the group includes the shell", () => {
    expect(planTermination({
      pane_id: "w1:p1",
      shell_pid: 100,
      foreground_process_group_id: 100,
      foreground_processes: [],
    }, [201, 200, 201, 100])).toEqual({
      kind: "processes",
      ids: [201, 200],
    });
  });

  test("refuses a shared shell group without verified agent processes", () => {
    expect(() => planTermination({
      pane_id: "w1:p1",
      shell_pid: 100,
      foreground_process_group_id: 100,
      foreground_processes: [],
    }, [])).toThrow("Refusing to terminate an unverified foreground process");
  });
});
