本文档翻译自`sched-eevdf.rst <https://gitee.com/chenxiaosonggitee/tmp/blob/master/kernel/sched-eevdf-origin.rst>`_，翻译时此文档未合入主线，还在next仓库里，当时next仓库里的最新提交是``602bce7e5edeb docs: scheduler: Start documenting the EEVDF scheduler``。大部分借助于ChatGPT翻译，仅作为我个人的参考，如果你想查阅，建议看英文文档，因为我不确定我记录的中文翻译是否完整和正确。

"最早可用虚拟截止时间优先" (EEVDF) 首次在1995年的一篇科学出版物中被提出 [1]。Linux内核在版本6.6中开始向EEVDF过渡（作为2024年的一个新选项），放弃了早期的完全公平调度器 (CFS)，转而采用了由Peter Zijlstra在2023年提出的EEVDF版本 [2-4]。更多关于CFS的信息可以在 Documentation/scheduler/sched-design-CFS.rst 中找到。

与CFS类似，EEVDF旨在为所有具有相同优先级的可运行任务均等分配CPU时间。为此，它为每个任务分配一个虚拟运行时间，从而创建一个“滞后”值，该值可用于确定任务是否已获得其公平的CPU时间份额。这样，具有正滞后的任务被欠CPU时间，而负滞后意味着任务已超出其份额。EEVDF选择滞后大于或等于零的任务，并为每个任务计算一个虚拟截止时间 (VD)，然后选择具有最早VD的任务作为下一个执行的任务。值得注意的是，这允许具有较短时间片的延迟敏感任务优先处理，从而有助于提高它们的响应能力。

关于如何管理滞后，尤其是对休眠任务的管理，目前仍在讨论中；但在撰写本文时，EEVDF基于虚拟运行时间 (VRT) 使用了一种“衰减”机制。这防止了任务通过短暂休眠来重置其负滞后的系统漏洞: 当任务休眠时，它仍保留在运行队列中，但标记为“延迟出队”，允许其滞后值随虚拟运行时间 (VRT)衰减。因此，长时间休眠的任务最终会重置其滞后值。最后，如果任务的VD较早，它们可以抢占其他任务，任务也可以使用新的 sched_setattr() 系统调用请求特定的时间片，这进一步促进了延迟敏感应用程序的工作。

参考文献

[1] https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=805acf7726282721504c8f00575d91ebfd750564

[2] https://lore.kernel.org/lkml/a79014e6-ea83-b316-1e12-2ae056bda6fa@linux.vnet.ibm.com/

[3] https://lwn.net/Articles/969062/

[4] https://lwn.net/Articles/925371/
