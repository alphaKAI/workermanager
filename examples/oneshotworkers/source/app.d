import workermanager;
import std.stdio,
       std.datetime;

void main() {
  writeln("<main> start!");
  WorkerManager wm = new WorkerManager;

  Worker[] workers = [
    Worker("abc", (Worker worker) {
      writeln("-<worker abc> ABC!");
      writeln("-<worker abc> worker.name : ", worker.name);

      foreach (idx; 0..10) { // complexe processes
        writeln("-<worker abc> loop, idx - ", idx);
      }
    }),
    Worker("def", {
      writeln("--<worker def> DEF!");
      foreach (idx; 0..10) { // complexe processes
        writeln("--<worker def> loop, idx - ", idx);
      }
    }),
    Worker("ghi", {
      writeln("---<worker ghi> GHI!");
      foreach (idx; 0..10) { // complexe processes
        writeln("---<worker ghi> loop, idx - ", idx);
      }
    })];
  
  wm.registerWorkers(workers);
  wm.joinAll;
}
