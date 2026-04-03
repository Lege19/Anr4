import { type Decoder } from "decoders";
import * as d from "decoders";
import { Auth } from "./auth";
import {
  cohortDecoder,
  courseDecoder,
  studentInfoDecoder,
  studentProgressDecoder,
  teacherInfoDecoder,
  topicDecoder,
  wordDecoder,
  type RowId,
  type StudentProgress,
} from "./types";

export class APIDecodeError extends Error {}

const JSON_CONTENT_TYPE = {
  "Content-Type": "application/json;charset=UTF-8",
};
const postJson =
  <T extends d.JSONValue>(url: string) =>
  (json: T) =>
    new Request(url, {
      method: "POST",
      headers: JSON_CONTENT_TYPE,
      body: JSON.stringify(json),
    });

async function fetchAndDecode<T>(
  resource: RequestInfo | URL,
  decoder: Decoder<T>,
): Promise<T> {
  const response = await Auth.fetch(resource);
  const decoded = decoder.decode(await response.json());
  if (decoded.ok) return decoded.value;
  throw new APIDecodeError(JSON.stringify(decoded.error));
}

const makeFetchAndDecode =
  <T, F extends unknown[]>(
    resource: (...args: F) => RequestInfo | URL,
    decoder: Decoder<T>,
  ) =>
  (...args: F) =>
    fetchAndDecode(resource(...args), decoder);

export const coreStudentInfo = makeFetchAndDecode(
  () => "/api/student_info",
  studentInfoDecoder,
);
export const coreTeacherInfo = makeFetchAndDecode(
  () => "/api/teacher_info",
  teacherInfoDecoder,
);
export const cohorts = makeFetchAndDecode(
  postJson<RowId[]>("/api/data/cohorts"),
  d.array(cohortDecoder),
);
export const courses = makeFetchAndDecode(
  postJson<RowId[]>("/api/data/courses"),
  d.array(courseDecoder),
);
export const topics = makeFetchAndDecode(
  postJson<{ tier: number | null; topics: RowId[] }>("/api/data/topics"),
  d.array(topicDecoder),
);
export const words = makeFetchAndDecode(
  postJson<RowId[]>("/api/data/words"),
  d.array(wordDecoder),
);
export const progress = makeFetchAndDecode(
  postJson<RowId[]>("/api/data/progress"),
  d.array(studentProgressDecoder),
);

export const pushChanges = (changes: StudentProgress[]) =>
  Auth.fetch("/api/progress/push", {
    method: "POST",
    headers: JSON_CONTENT_TYPE,
    body: JSON.stringify(changes),
  });
