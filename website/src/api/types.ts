import * as d from "decoders";

type ExtractType<T> = T extends d.Decoder<infer X> ? Readonly<X> : never;

export type RowId = string;
export const rowIdDecoder: d.Decoder<RowId> = d.string;

// Will need updating if the server changes how it serializes `access_token::AccountKind`
export const AccountKind = { Student: "Student", Teacher: "Teacher" } as const;
export type AccountKind = (typeof AccountKind)[keyof typeof AccountKind];
const ACCOUNT_KINDS: Readonly<AccountKind[]> = Object.values(AccountKind);
function isAccountKind(s: unknown): s is AccountKind {
  return ACCOUNT_KINDS.includes(s as any);
}
const accountKindDecoder: d.Decoder<AccountKind> = d.string.refine(
  isAccountKind,
  "Unexpected account kind, expecting 'student' or 'teacher'",
);

export type UnixTime = number;

const unixTimestampDecoder: d.Decoder<UnixTime> = d.number;

export const accessTokenClaimsDecoder = d.object({
  id: rowIdDecoder,
  kind: accountKindDecoder,
  fingerprint: d.string,
  expiration: unixTimestampDecoder,
});
export type AccessTokenClaims = ExtractType<typeof accessTokenClaimsDecoder>;

export const studentInfoDecoder = d.object({
  studentId: rowIdDecoder,
  schoolId: rowIdDecoder,
  isDyslexic: d.nullable(d.boolean),
  forename: d.string,
  surname: d.string,
  cohorts: d.record(
    rowIdDecoder,
    d.object({
      tier: d.positiveInteger,
      classId: rowIdDecoder,
    }),
  ),
});
export type CoreStudentInfo = ExtractType<typeof studentInfoDecoder>;

export const teacherInfoDecoder = d.object({
  teacherId: rowIdDecoder,
  schoolId: rowIdDecoder,
  forename: d.string,
  surname: d.string,
});
export type CoreTeacherInfo = ExtractType<typeof teacherInfoDecoder>;

export const cohortDecoder = d.object({
  cohortId: rowIdDecoder,
  schoolId: rowIdDecoder,
  name: d.string,
  tierCount: d.number,
  courses: d.array(rowIdDecoder),
});
export type Cohort = ExtractType<typeof cohortDecoder>;

export const courseDecoder = d.object({
  courseId: rowIdDecoder,
  name: d.string,
  targetLanguage: d.string,
  homeLanguage: d.string,
  tierCount: d.positiveInteger,
  topics: d.array(rowIdDecoder),
});
export type Course = ExtractType<typeof courseDecoder>;

export const topicDecoder = d.object({
  topicId: rowIdDecoder,
  courseId: rowIdDecoder,
  name: d.string,
  words: d.array(rowIdDecoder),
  loadedToTier: d.nullable(d.number),
});
export type Topic = ExtractType<typeof topicDecoder>;

export const wordDecoder = d.object({
  wordId: rowIdDecoder,
  topicId: rowIdDecoder,
  headword: d.string,
  translation: d.string,
  tier: d.number,
  partOfSpeech: d.nullable(d.string),
});
export type Word = ExtractType<typeof wordDecoder>;

export const studentProgressDecoder = d.object({
  wordId: rowIdDecoder,
  studentId: rowIdDecoder,
  easeFactor: d.number,
  testInterval: d.number,
  lastTest: d.nullable(unixTimestampDecoder),
});
export type StudentProgress = ExtractType<typeof studentProgressDecoder>;
