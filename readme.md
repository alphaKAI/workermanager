#WorkerManager
Multi-thread based asynchronized worker manager.  

##Requirements

DMD v2.071.2 or later
DUB 1.0.0 or later

##Example
###one-shot workers
```d:examples/oneshotworkers/source/app.d
import workermanager;
import std.stdio;

void main() {
  writeln("<main> start!");
  WorkerManager wm = new WorkerManager;

  Worker[] workers = [
    Worker("abc", (Worker worker) {
      writeln("-<worker abc> ABC!");
      writeln("-<worker abc> worker.name : ", worker.name);

      foreach (idx; 0..10) { // complex processes
        writeln("-<worker abc> loop, idx - ", idx);
      }
    }),
    Worker("def", {
      writeln("--<worker def> DEF!");
      foreach (idx; 0..10) { // complex processes
        writeln("--<worker def> loop, idx - ", idx);
      }
    }),
    Worker("ghi", {
      writeln("---<worker ghi> GHI!");
      foreach (idx; 0..10) { // complex processes
        writeln("---<worker ghi> loop, idx - ", idx);
      }
    })];

  wm.registerWorkers(workers);
  wm.joinAll;
}
```

####Outputs
```
<main> start!
<worker - abc> worker "abc" is spawned!
<worker - ghi> worker "ghi" is spawned!
<worker - def> worker "def" is spawned!
---<worker ghi> GHI!
-<worker abc> ABC!
--<worker def> DEF!
---<worker ghi> loop, idx - 0
-<worker abc> worker.name : abc
--<worker def> loop, idx - 0
---<worker ghi> loop, idx - 1
-<worker abc> loop, idx - 0
--<worker def> loop, idx - 1
---<worker ghi> loop, idx - 2
-<worker abc> loop, idx - 1
--<worker def> loop, idx - 2
---<worker ghi> loop, idx - 3
-<worker abc> loop, idx - 2
--<worker def> loop, idx - 3
---<worker ghi> loop, idx - 4
-<worker abc> loop, idx - 3
--<worker def> loop, idx - 4
---<worker ghi> loop, idx - 5
-<worker abc> loop, idx - 4
--<worker def> loop, idx - 5
---<worker ghi> loop, idx - 6
-<worker abc> loop, idx - 5
--<worker def> loop, idx - 6
---<worker ghi> loop, idx - 7
-<worker abc> loop, idx - 6
--<worker def> loop, idx - 7
---<worker ghi> loop, idx - 8
-<worker abc> loop, idx - 7
--<worker def> loop, idx - 8
---<worker ghi> loop, idx - 9
-<worker abc> loop, idx - 8
--<worker def> loop, idx - 9
-<worker abc> loop, idx - 9
```

Asynchronized!

###periodic workers
This feature is more useful.  
You can operate asynchronized&scheduled loop process.  

```d:examples/periodicworkers/source/app.d
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
}

```

####Outputs
```
<main> start!
<worker - abc> worker "abc" is spawned!
<worker - ghi> worker "ghi" is spawned!
<worker - def> worker "def" is spawned!
-<worker abc> ABC!, counter - 0
-<worker abc> ABC!, counter - 1
-<worker abc> ABC!, counter - 2
-<worker abc> ABC!, counter - 3
--<worker def> DEF!
-<worker abc> ABC!, counter - 4
-<worker abc> ABC!, counter - 5
-<worker abc> ABC!, counter - 6
---<worker ghi> GHI!
-<worker abc> ABC!, counter - 7
--<worker def> DEF!
-<worker abc> ABC!, counter - 8
-<worker abc> ABC!, counter - 9
-<worker abc> ABC!, counter - 10
-<worker abc> ABC!, counter - 11
--<worker def> DEF!
-<worker abc> ABC!, counter - 12
-<worker abc> ABC!, counter - 13
-<worker abc> ABC!, counter - 14
---<worker ghi> GHI!
-<worker abc> ABC!, counter - 15
--<worker def> DEF!
-<worker abc> ABC!, counter - 16
-<worker abc> ABC!, counter - 17
-<worker abc> ABC!, counter - 18
-<worker abc> ABC!, counter - 19
-<worker abc> Suspend worker - abc
<WorkerManager> Suspended worker - abc
<worker - abc> suspended!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> DEF!
---<worker ghi> GHI!
--<worker def> DEF!
--<worker def> Suspend worker - def & ghi
<WorkerManager> Suspended worker - def
<WorkerManager> Suspended worker - ghi
<worker - def> suspended!
<worker - ghi> suspended!
```

##LICENSE
Copyright (C) 2017, Akihiro Shoji  
WorkerManager is released under the MIT License.  
Please see `LICENSE` file for details.  
