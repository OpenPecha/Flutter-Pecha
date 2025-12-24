import 'package:flutter_pecha/features/ai/models/chat_message.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';

/// Dummy data source for thread operations
/// This will be replaced with real API calls later
class ThreadDatasourceDummy {
  // Simulate network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Get list of all threads
  Future<ThreadListResponse> getThreads({
    int skip = 0,
    int limit = 20,
  }) async {
    await _simulateDelay();

    final threads = [
      ChatThreadSummary(
        id: 'thread-1',
        title: 'What is self?',
      ),
      ChatThreadSummary(
        id: 'thread-2',
        title: 'How to attain enlightenment?',
      ),
      ChatThreadSummary(
        id: 'thread-3',
        title: 'Explain the concept of karma',
      ),
      ChatThreadSummary(
        id: 'thread-4',
        title: 'What is meditation?',
      ),
      ChatThreadSummary(
        id: 'thread-5',
        title: 'Understanding the Four Noble Truths',
      ),
    ];

    return ThreadListResponse(
      data: threads,
      total: threads.length,
    );
  }

  /// Get specific thread by ID with all messages
  Future<ChatThreadDetail> getThreadById(String threadId) async {
    await _simulateDelay();

    // Return different dummy data based on thread ID
    switch (threadId) {
      case 'thread-1':
        return ChatThreadDetail(
          id: 'thread-1',
          title: 'What is self?',
          messages: [
            ThreadMessage(
              role: 'user',
              content: 'What is self?',
              id: 'msg-1-1',
            ),
            ThreadMessage(
              role: 'assistant',
              content:
                  'The concept of "self" is related to the idea of "no-self" (བདག་མེད་). The absence of self in a person means that there is no inherent nature of self. When the aggregates that constitute a person are not realized as being without inherent existence, one has not realized the absence of self of a person.\n\nIt\'s a deep topic, and it sounds like understanding "self" involves understanding "no-self" and the nature of reality! Would you like to explore any of these aspects further?',
              id: 'msg-1-2',
              searchResults: [
                SearchResult(
                  id: 'xcdDbp2XjCM3c8CwSuHqk',
                  title: 'དབུ་མ་ལ་འཇུག་པའི་འགྲེལ་བཤད་ཅེས་བྱ་བ།',
                  text: 'གང་ཟག་གི་བདག་མེད་པ་ནི་བདག་གི་རང་བཞིན་མེད་པ་ཉིད་ཡིན་ལ།',
                  score: 0.95,
                  distance: 0.05,
                ),
              ],
            ),
          ],
        );

      case 'thread-2':
        return ChatThreadDetail(
          id: 'thread-2',
          title: 'How to attain enlightenment?',
          messages: [
            ThreadMessage(
              role: 'user',
              content: 'How can one attain enlightenment?',
              id: 'msg-2-1',
            ),
            ThreadMessage(
              role: 'assistant',
              content:
                  'Attaining enlightenment requires following the Noble Eightfold Path, which consists of right view, right intention, right speech, right action, right livelihood, right effort, right mindfulness, and right concentration.\n\nThe path involves developing wisdom, ethical conduct, and mental discipline through meditation and mindful living.',
              id: 'msg-2-2',
              searchResults: [
                SearchResult(
                  id: 'path-1',
                  title: 'The Noble Eightfold Path',
                  text: 'འཕགས་པའི་ལམ་ཡན་ལག་བརྒྱད།',
                  score: 0.92,
                  distance: 0.08,
                ),
              ],
            ),
            ThreadMessage(
              role: 'user',
              content: 'How long does it take?',
              id: 'msg-2-3',
            ),
            ThreadMessage(
              role: 'assistant',
              content:
                  'The time required varies for each individual. Some may achieve enlightenment in a single lifetime through dedicated practice, while others may take many lifetimes. What matters most is sincere effort and consistent practice.',
              id: 'msg-2-4',
            ),
          ],
        );

      case 'thread-3':
        return ChatThreadDetail(
          id: 'thread-3',
          title: 'Explain the concept of karma',
          messages: [
            ThreadMessage(
              role: 'user',
              content: 'Can you explain karma?',
              id: 'msg-3-1',
            ),
            ThreadMessage(
              role: 'assistant',
              content:
                  'Karma (ལས་) refers to the law of cause and effect. Every action—physical, verbal, or mental—creates consequences. Positive actions lead to positive results, while negative actions lead to suffering.\n\nKarma is not fatalistic; we have the power to create new karma through our choices and actions.',
              id: 'msg-3-2',
              searchResults: [
                SearchResult(
                  id: 'karma-1',
                  title: 'Understanding Karma',
                  text: 'ལས་ནི་རྒྱུ་འབྲས་ཀྱི་ཆོས་ཉིད།',
                  score: 0.88,
                  distance: 0.12,
                ),
              ],
            ),
          ],
        );

      case 'thread-4':
        return ChatThreadDetail(
          id: 'thread-4',
          title: 'What is meditation?',
          messages: [
            ThreadMessage(
              role: 'user',
              content: 'What is meditation and why is it important?',
              id: 'msg-4-1',
            ),
            ThreadMessage(
              role: 'assistant',
              content:
                  'Meditation (བསམ་གཏན་) is a practice of training the mind to develop concentration, clarity, and inner peace. It involves techniques like mindfulness of breathing, loving-kindness meditation, and analytical meditation.\n\nMeditation is essential for calming the mind, developing insight into the nature of reality, and ultimately achieving liberation from suffering.',
              id: 'msg-4-2',
              searchResults: [
                SearchResult(
                  id: 'meditation-1',
                  title: 'Meditation Practices',
                  text: 'བསམ་གཏན་གྱི་སྒོམ་ཚུལ།',
                  score: 0.90,
                  distance: 0.10,
                ),
              ],
            ),
          ],
        );

      case 'thread-5':
        return ChatThreadDetail(
          id: 'thread-5',
          title: 'Understanding the Four Noble Truths',
          messages: [
            ThreadMessage(
              role: 'user',
              content: 'What are the Four Noble Truths?',
              id: 'msg-5-1',
            ),
            ThreadMessage(
              role: 'assistant',
              content:
                  'The Four Noble Truths (བདེན་པ་བཞི་) are the foundation of Buddhist teachings:\n\n1. The truth of suffering (སྡུག་བསྔལ་)\n2. The truth of the cause of suffering (ཀུན་འབྱུང་)\n3. The truth of the cessation of suffering (འགོག་པ་)\n4. The truth of the path leading to the cessation of suffering (ལམ་)\n\nThese truths describe the nature of existence and the path to liberation.',
              id: 'msg-5-2',
              searchResults: [
                SearchResult(
                  id: 'truths-1',
                  title: 'Four Noble Truths',
                  text: 'འཕགས་པའི་བདེན་པ་བཞི།',
                  score: 0.94,
                  distance: 0.06,
                ),
              ],
            ),
          ],
        );

      default:
        throw Exception('Thread not found');
    }
  }
}

