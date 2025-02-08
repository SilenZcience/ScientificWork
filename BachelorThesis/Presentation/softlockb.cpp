send_solver_interrupts("all"); // implemented workaround

while (true) {
    { // wait for threads to finish
    std::lock_guard<std::mutex> threads_guard(running_threads_mutex);
    if (running_threads.size() == 0)
        break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
}
