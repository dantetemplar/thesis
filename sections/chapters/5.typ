= Conclusion

This thesis addressed an operationally important problem in educational timetabling: not only generating a feasible timetable, but maintaining it under continuous disturbances after publication. The work was grounded in real scheduling practice at Innopolis University and focused on integrating optimization, validation, and human-controlled editing into one workflow.

The central result is an implemented interactive assistant that supports both baseline timetable construction and post-publication adaptation. Instead of treating scheduling as a one-shot optimization task, the system treats timetable lifecycle management as a sequence of decisions: prepare structured institutional data, generate a stable weekly baseline, inspect conflicts and quality indicators, apply local calendar-level edits, and synchronize approved changes with room-booking operations.

== Main Results

The thesis achieved the engineering objectives defined in Chapter 1 and implemented in Chapters 3-4.

First, a practical Curriculum-Based Course Timetabling (CB-CTT) model was implemented with explicit hard constraints and phase-based soft optimization. The model supports mixed audience structures (shared and per-group classes), selector-driven group expansion, co-teaching alternatives, and dual-role conflict checks for users who are both instructors and students.

Second, a two-stage planning approach was operationalized. Stage A builds a stable weekly reference structure; Stage B supports user-driven calendar adaptation with diagnostics and optional solver-assisted local repair. This reflects how scheduling is actually performed in universities: planners reason in reusable weekly patterns, but execute changes on concrete dates under dynamic disturbances.

Third, a verification layer was integrated as a first-class component of the workflow. The checks subsystem reports conflicts, required-meeting violations, ordering/coherence issues, room-capacity risks, workload imbalance, and booking consistency problems. This makes acceptance of timetable versions evidence-based and transparent.

Fourth, the system was integrated with existing institutional practices. Legacy Google Sheets data can be migrated through parser and normalization steps; Outlook-based room booking is used for conflict detection and synchronization of approved changes. This integration focus addresses a key barrier to adoption identified in prior studies @oude-vrielink2019 @Kingston2013.

== Scientific and Practical Contribution

The contribution of this thesis is not a new standalone optimization algorithm. The contribution is an implementable architecture and workflow for timetable maintenance in real institutions, where optimization quality, user control, and operational integration must coexist.

From a research perspective, the thesis strengthens the argument that post-publication maintenance is central, not peripheral, to timetabling practice @veenstra2016 @Lindahl2018. From an engineering perspective, it demonstrates that a CB-CTT-based solver can be embedded into a user-centered platform with explicit diagnostics and booking-aware operations.

In practical terms, the developed assistant replaces fragmented tooling (spreadsheets, ad hoc scripts, manual booking checks) with a coherent process that supports:

- reproducible solve artifacts and logs;
- transparent conflict and quality diagnostics;
- controlled human-in-the-loop timetable adaptation;
- faster synchronization between timetable decisions and room-booking state.

== Limitations

Several limitations remain and should be considered when interpreting results.

The current implementation is tailored to one institutional context, including local governance and booking practices. While the core approach is transferable, broader deployment may require adaptation of data models, policy rules, and integration endpoints.

The evaluation context is a relatively small university (around 2,000 students). Larger institutions can be 10x bigger and significantly more complex (multi-campus operations, multi-department coordination, heterogeneous policies), so additional scaling and governance adaptations are expected for such settings.

Weekly baseline optimization and calendar-level adaptation are intentionally separated. This improves operational control, but also means some date-specific constraints are handled later in the workflow instead of in one monolithic solve.

Data quality remains a practical dependency: late curriculum updates, incomplete room-feature inventories, and evolving instructor availability can reduce planning stability regardless of solver quality.

Finally, the assistant currently supports decision-making and synchronization but does not fully automate all communication and SIS-level institutional processes end-to-end.

== Future Work

Future development should focus on strengthening both model capability and operational integration.

At the optimization level, future work can extend perturbation metrics for Stage B and evaluate alternative neighborhood search or repair strategies for faster local adaptation under strict stability guarantees.

At the workflow level, further integration with Student Information Systems and notification channels can reduce manual coordination overhead and improve traceability of approved changes.

The same workflow can also be adopted in simpler educational contexts, such as schools and colleges, where constraints are usually less heterogeneous but transparency, conflict checks, and controllable edits remain critical.

At the evaluation level, multi-institution studies with standardized datasets and operational KPIs are needed to quantify transferability, usability impact, and long-term adoption outcomes. Such studies would complement algorithmic benchmarking by measuring real deployment success.

At the AI-support level, LLM-based assistants could be explored for explainable recommendations, conflict triage, and what-if scenario guidance, while preserving hard-constraint guarantees and user authority over final decisions.

== Final Remarks

Educational timetable management is fundamentally a socio-technical process: computationally hard, operationally dynamic, and organizationally constrained. This thesis shows that useful progress comes from combining formal optimization with transparent checks, user-centered interaction, and workflow-native integration.

The resulting system demonstrates a practical path from academic timetabling methods to deployable institutional tooling. By unifying CB-CTT modeling, iterative maintenance support, and booking-aware operations in one assistant, the work contributes a concrete foundation for reliable timetable management under real educational constraints.