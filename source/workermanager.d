module workermanager;
import core.sync.mutex;
import core.thread,
       core.time;
import std.typecons,
       std.stdio;
import libasync;

enum WorkerStatus {
  Suspended,
  Running
}

struct Worker {
  string   name;
  Duration durx;
  void delegate(Worker) dg;
  private {
    bool periodic;
  }

  this (string name, Duration durx, void delegate(Worker worker) dg) {
    this.name = name;
    this.durx = durx;
    this.dg   = dg;
    this.periodic = true;
  }

  this (string name, Duration durx, void delegate() dg) {
    this.name = name;
    this.durx = durx;
    this.dg   = (Worker worker) => dg();
    this.periodic = true;
  }

    this (string name, void delegate(Worker worker) dg) {
    this.name = name;
    this.dg   = dg;
  }

  this (string name, void delegate() dg) {
    this.name = name;
    this.dg   = (Worker worker) => dg();
  }
}

class WorkerManager {
  WorkerStatus[string] workers;
  ThreadGroup tg;
  Mutex m;

  this() {
    this.m = new Mutex;
    this.tg = new ThreadGroup;
  }

  void registerWorkers(Worker[] _workers) {
    foreach (worker; _workers) {
      this.registerWorker(worker);
    }
  }

  void registerWorker(Worker worker) {
    Nullable!WorkerStatus _sts = this.getWorkerStatus(worker.name);

    if (_sts.isNull) {
      this.setWorkerStatus(worker.name, WorkerStatus.Running);
      startWorker(worker);
    } else {
      WorkerStatus sts = _sts.get;
      if (sts.Running) {
        debug writeln("The worker already exists!");
      } else {
        debug writeln("The worker have been suspended, then restart");
        this.setWorkerStatus(worker.name, WorkerStatus.Running);
        startWorker(worker);
      }
    }
  }

  private void startWorker(Worker worker) {
    auto _dg = (Worker _worker) => () => workerMain(_worker);
    synchronized (m) {
      tg.create(_dg(worker));
    }
  }

  void suspendWorker(string workerName) {
    Nullable!WorkerStatus _sts = this.getWorkerStatus(workerName);

    if (!_sts.isNull) {
      WorkerStatus sts = _sts.get;
      if (sts.Running) {
        debug writefln("<WorkerManager> Suspended worker - %s", workerName);
        this.setWorkerStatus(workerName, WorkerStatus.Suspended);
      }
    }
  }

  void workerMain(Worker worker) {
    debug writefln("<worker - %s> worker \"%s\" is spawned!", worker.name, worker.name);

    auto ev_loop = getThreadEventLoop();
    auto timer   = new AsyncTimer(ev_loop);

    if (worker.periodic) {
      timer.duration(worker.durx).periodic.run({
        worker.dg(worker);
      });

      while (ev_loop.loop()) {
        WorkerStatus sts = getWorkerStatus(worker.name).get;
        if (sts == WorkerStatus.Suspended) {
          debug writefln("<worker - %s> suspended!", worker.name);
          break;
        }
      }
    } else {
      worker.dg(worker);
      workers[worker.name] = WorkerStatus.Suspended;
    }
  }

  Nullable!WorkerStatus getWorkerStatus(string workerName) {
    if (workerName in this.workers) {
      synchronized (this.m) {
        return nullable(this.workers[workerName]);
      }
    } else {
      return typeof(return).init;
    }
  }

  void setWorkerStatus(string workerName, WorkerStatus WorkerStatus) {
    synchronized (m) {
      this.workers[workerName] = WorkerStatus;
    }
  }

  Thread createWaitLoop() {
    auto th = new Thread({
      bool flag;

      do {
        WorkerStatus[] statuses;
        bool m_flag;

        synchronized (m) {
          statuses = workers.values;
        }

        foreach (status; statuses) {
          if (status == WorkerStatus.Running) {
            m_flag = true;
            break;
          }
        }

        if (m_flag) {
          continue;
        } else {
          flag = true;
        }
      } while (!flag);
    });

    th.start;

    return th;
  }

  void joinAll() {
    this.tg.joinAll;
  }

  bool checkAllFinished() {
    foreach (worker; workers.values) {
      if (worker == WorkerStatus.Running) {
        return false;
      }
    }

    return true;
  }
}
