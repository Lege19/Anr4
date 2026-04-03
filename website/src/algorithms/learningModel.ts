import { type RowId, type StudentProgress, type Word } from "@/api/types";
import { World, type TableView } from "@/api/world";
import { viewProxy } from "@/util";

export abstract class Question {
  public readonly word: Word;
  constructor(word: Word) {
    this.word = word;
    Object.freeze(this);
  }

  public abstract get correctAnswer(): string;

  public abstract get question(): string;
}

export class ReadingQuestion extends Question {
  public override get correctAnswer() {
    return this.word.translation;
  }
  public override get question() {
    return this.word.headword;
  }
}
export class WritingQuestion extends Question {
  public override get correctAnswer() {
    return this.word.headword;
  }
  public override get question() {
    return this.word.translation;
  }
}

export type LearningModelParams = {
  topicIds: RowId[];
  tier: number | null;
};

function secondsNow(): number {
  return Date.now() / 1000;
}

function compensateDyslexic(correctness: number): number {
  return Math.min(correctness / 0.8, 1);
}

class _LearningModel implements LearningModel {
  private readonly progress: TableView<StudentProgress>;
  constructor(progress: TableView<StudentProgress>) {
    this.progress = progress;
  }
  async send(question: Question, correctness: number): Promise<void> {
    if (World.studentInfo()?.isDyslexic) {
      correctness = compensateDyslexic(correctness);
    }
    const progress = { ...this.progress[question.word.wordId]! };
    progress.easeFactor = Math.max(
      1.3,
      progress.easeFactor -
        0.8 +
        1.4 * correctness -
        0.5 * correctness * correctness,
    );
    progress.testInterval *= progress.easeFactor;
    progress.lastTest = Date.now() / 1000;
    World.setProgress(progress);
  }
  async getQuestion(): Promise<Question> {
    if (Object.keys(this.progress).length === 0)
      throw new Error(
        "Cannot get question, there are no availible words to choose from",
      );
    const NEW_WORD_COST = 0.4;
    const now = secondsNow();
    let bestCost = Infinity;
    let bestWordId!: RowId;

    for (const wordId in this.progress) {
      const progress = this.progress[wordId]!;
      const cost = progress.lastTest
        ? Math.abs(Math.log((now - progress.lastTest) / progress.testInterval))
        : NEW_WORD_COST;
      if (cost < bestCost) {
        bestCost = cost;
        bestWordId = wordId;
      }
    }

    const word = await World.words.get(bestWordId);

    return new (Math.random() >= 0.5 ? ReadingQuestion : WritingQuestion)(word);
  }

  private static async newAsync({
    topicIds,
    tier,
  }: LearningModelParams): Promise<LearningModel> {
    const topics = await World.topics.loadNeeded(topicIds, tier);
    const wordIds = Object.values(topics).flatMap((topic) => topic.words);
    const [progress, words] = await Promise.all([
      World.progress.loadNeeded(wordIds),
      World.words.loadNeeded(wordIds),
    ]);
    // filter out words that don't have high enough tier
    const filteredProgress =
      tier !== null
        ? viewProxy(
            progress,
            Object.values(words)
              .filter((word) => word.tier <= tier)
              .map((word) => word.wordId),
          )
        : progress;
    return new _LearningModel(filteredProgress);
  }
  public static new(params: LearningModelParams): LearningModel {
    return makeImmediate(_LearningModel.newAsync(params));
  }
}

interface LearningModel {
  send(question: Question, correctness: number): Promise<void>;
  getQuestion(): Promise<Question>;
}

function makeImmediate(learningModel: Promise<LearningModel>): LearningModel {
  type Send = LearningModel["send"];
  type GetQuestion = LearningModel["getQuestion"];
  const out = {
    learningModel,
    async send(...args: Parameters<Send>): ReturnType<Send> {
      return (await learningModel).send(...args);
    },
    async getQuestion(
      ...args: Parameters<GetQuestion>
    ): ReturnType<GetQuestion> {
      return (await learningModel).getQuestion(...args);
    },
  };
  learningModel.then((learningModel) => {
    out.send = learningModel.send.bind(learningModel);
    out.getQuestion = learningModel.getQuestion.bind(learningModel);
  });
  return out;
}

export function LearningModel(params: LearningModelParams): LearningModel {
  if (params.topicIds.length === 0)
    throw new Error("Cannot make learning model without any topics");
  return _LearningModel.new(params);
}
