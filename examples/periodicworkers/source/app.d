import workermanager;
import std.stdio,
       std.datetime;

void main() {
  writeln("<main> start!");
  WorkerManager wm = new WorkerManager;

  Worker[] workers = [
    Worker("abc", dur!"msecs"(100), ((WorkerManager wm) => {
      static size_t counter;
      writeln("-<worker abc> ABC!, counter - ", counter++);

      if (counter == 20) {
        writeln("-<worker abc> Suspend worker - abc");
        wm.suspendWorker("abc");
      }
    })(wm)),
    Worker("def", dur!"msecs"(500), (Worker thisWorker) {
      static size_t counter;
      writeln("--<worker def> DEF!");
      counter++;

      if (counter == 20) {
      writeln("--<worker def> Suspend worker - def & ghi");
        wm.suspendWorker(thisWorker.name);
        wm.suspendWorker("ghi");
      }
    }),
    Worker("ghi", dur!"msecs"(1000), {
      writeln("---<worker ghi> GHI!");
    })];
  
  wm.registerWorkers(workers);
  wm.joinAll;
  /*
    You can wait workers by wm.createWaitLoop function.
    The function waits by looping while there is Running statused worker.
    wm.joinAll implicitly excepts all of worker is never called after the worker once terminated.
    But createWaitLoop excepts all of worker's status is Suspended, this means that createWaitLoop is status driven.
    joinAll is grater than createWaitLoop in view of performance, but createWaitLoop is clearer than joinAll in view of semantics.
  */
}
