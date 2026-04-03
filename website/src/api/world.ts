import type {
  Cohort,
  CoreStudentInfo,
  CoreTeacherInfo,
  Course,
  RowId,
  StudentProgress,
  Topic,
  Word,
} from "./types";
import * as api from ".";
import { runPeriodicallyAndBeforeExit, viewProxy } from "@/util";
import { createAsync } from "@solidjs/router";
import { Auth } from "./auth";
import { createRoot, type Accessor } from "solid-js";

type Table<T> = Record<RowId, T>;
export type TableView<T> = Readonly<Record<RowId, T>>;

const makeLoader = <I extends string, T extends { [P in I]: RowId }>(
  table: Table<T>,
  idField: I,
  fetcher: (ids: RowId[]) => Promise<T[]>,
) => ({
  async loadExact(ids: RowId[]): Promise<void> {
    for (const record of await fetcher(ids)) {
      table[record[idField]] = record;
    }
  },
  /**
   * Ensures the requested ids are available in the table,
   * ids that already exist are not fetched again
   *
   * @param ids - An array of {@link RowId}
   * @returns a Readonly record guaranteed to contain the keys requested
   */
  async loadNeeded(ids: RowId[]): Promise<TableView<T>> {
    const neededIds = ids.filter((id) => !(id in table));
    if (neededIds.length !== 0) await this.loadExact(neededIds);

    return viewProxy(table, ids);
  },
  async get(id: RowId): Promise<T> {
    this.loadNeeded([id]);
    return table[id]!;
  },
});
type Loader<I extends string, T extends { [P in I]: RowId }> = ReturnType<
  typeof makeLoader<string, T>
>;

type StudentInfoCohort = Cohort & CoreStudentInfo["cohorts"][0];
type StudentInfoCourse = Course & { tier: number };
type StudentInfo = Omit<CoreStudentInfo, "cohorts"> & {
  cohorts: TableView<StudentInfoCohort>;
  courses: TableView<StudentInfoCourse>;
};

class WorldManager {
  public readonly studentInfo: Accessor<StudentInfo | undefined>;
  public readonly teacherInfo: Accessor<CoreTeacherInfo | undefined>;

  readonly cache: {
    readonly cohorts: Table<Cohort>;
    readonly courses: Table<Course>;
    readonly topics: Table<Topic>;
    readonly words: Table<Word>;
    readonly progress: Table<StudentProgress>;
  } = { cohorts: {}, courses: {}, topics: {}, words: {}, progress: {} };

  private readonly dirtyProgress: Set<RowId> = new Set();

  public readonly cohorts: Loader<"cohortId", Cohort>;
  public readonly courses: Loader<"courseId", Course>;
  public readonly topics;
  public readonly words: Loader<"wordId", Word>;
  public readonly progress: Loader<"wordId", StudentProgress>;

  constructor() {
    this.studentInfo = createAsync(
      async (): Promise<undefined | StudentInfo> => {
        if (Auth.studentId() === undefined) return undefined;
        const coreStudentInfo = await api.coreStudentInfo();
        const cohorts = await this.cohorts.loadNeeded(
          Object.keys(coreStudentInfo.cohorts),
        );

        const cohortsClone: Table<StudentInfoCohort> = {};
        for (const cohort of Object.values(cohorts)) {
          const extraCohortFields = coreStudentInfo.cohorts[cohort.cohortId]!;
          cohortsClone[cohort.cohortId] = { ...cohort, ...extraCohortFields };
        }
        const courseTiers: Table<number> = {};
        for (const cohort of Object.values(cohortsClone)) {
          for (const courseId of cohort.courses) {
            if (courseId in courseTiers) {
              courseTiers[courseId] = Math.max(
                courseTiers[courseId]!,
                cohort.tier,
              );
            } else {
              courseTiers[courseId] = cohort.tier;
            }
          }
        }

        const courses = await this.courses.loadNeeded(
          Object.values(cohorts).flatMap((cohort) => cohort.courses),
        );

        const coursesClone: Table<StudentInfoCourse> = {};
        for (const course of Object.values(courses)) {
          coursesClone[course.courseId] = {
            ...course,
            tier: courseTiers[course.courseId]!,
          };
        }

        return {
          ...coreStudentInfo,
          cohorts: cohortsClone,
          courses: coursesClone,
        };
      },
    ) satisfies Accessor<StudentInfo | undefined>;

    this.teacherInfo = createAsync(async () => {
      if (Auth.teacherId() === undefined) return undefined;
      return api.coreTeacherInfo();
    });

    this.cohorts = makeLoader(this.cache.cohorts, "cohortId", api.cohorts);
    this.courses = makeLoader(this.cache.courses, "courseId", api.courses);
    this.topics = ((topics) => ({
      async loadExact(topic_ids: RowId[], tier: number | null): Promise<void> {
        for (const topic of await api.topics({
          topics: topic_ids,
          tier,
        })) {
          topics[topic.topicId] = topic;
        }
      },
      /**
       * Ensures the requested topics are availible to at least the requested tier.
       * ids that already exist are not fetched again
       *
       * @param ids - An array of {@link RowId}
       * @returns a Readonly record guaranteed to contain the keys requested
       */
      async loadNeeded(
        ids: RowId[],
        tier: number | null,
      ): Promise<TableView<Topic>> {
        const neededIds = ids.filter((id) => {
          if (!(id in topics)) return true;
          const currentTier = topics[id]!.loadedToTier;
          if (currentTier === null) return false;
          if (tier === null) return true;
          if (currentTier >= tier) return false;
          return true;
        });
        if (neededIds.length !== 0) await this.loadExact(neededIds, tier);

        return viewProxy(topics, ids);
      },
      async get(id: RowId, tier: number | null): Promise<Topic> {
        this.loadNeeded([id], tier ?? null);
        return topics[id]!;
      },
    }))(this.cache.topics);
    this.words = makeLoader(this.cache.words, "wordId", api.words);
    this.progress = Object.assign(
      makeLoader(this.cache.progress, "wordId", api.progress),
    );

    runPeriodicallyAndBeforeExit(this.pushChangedProgress.bind(this), 10_000);
  }
  async setProgress(value: StudentProgress) {
    this.cache.progress[value.wordId] = value;
    this.dirtyProgress.add(value.wordId);
  }
  async pushChangedProgress() {
    if (this.dirtyProgress.size === 0) return;
    const changesArray = Array.from(this.dirtyProgress).map(
      (id) => this.cache.progress[id]!,
    );
    this.dirtyProgress.clear();
    await api.pushChanges(changesArray);
  }
}

export const World = createRoot(() => new WorldManager());
