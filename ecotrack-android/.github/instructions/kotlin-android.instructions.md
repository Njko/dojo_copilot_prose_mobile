---
applyTo: "**/*.kt"
---

# Kotlin & Android Coding Instructions — EcoTrack

These instructions apply to all `.kt` files in the project.
GitHub Copilot must follow these conventions for every suggestion.

## Kotlin language conventions

### Nullability

Prefer non-null types everywhere in the domain layer.
Use `Result<T>` instead of nullable return types for fallible operations.

```kotlin
// Preferred
fun findHabit(id: HabitId): Result<Habit>

// Avoid
fun findHabit(id: HabitId): Habit?
```

In the data layer, nullable returns from Room are acceptable and expected.

### Immutability

Domain objects are immutable `data class`. Mutation produces a new instance via `copy()`.

```kotlin
// Correct
val updated = habit.complete(on = LocalDate.now())

// Wrong — data classes have no setters
habit.completions = ...
```

### Sealed classes for state

Use `sealed class` or `sealed interface` for UI state and domain events.

```kotlin
sealed interface HabitListUiState {
    data object Loading : HabitListUiState
    data class Success(val habits: List<HabitUiModel>) : HabitListUiState
    data class Error(val message: String) : HabitListUiState
}
```

### Coroutines

- Use `suspend fun` in repository interfaces and use cases
- Use `viewModelScope.launch` in ViewModels
- Use `withContext(Dispatchers.IO)` in data layer implementations
- Never block the main thread — no `runBlocking` outside of tests

```kotlin
// Repository interface (domain layer — no Dispatcher concern)
interface HabitRepository {
    suspend fun findById(id: HabitId): Habit?
    suspend fun save(habit: Habit)
    fun observeAll(): Flow<List<Habit>>
}

// Implementation (data layer — IO dispatcher)
class HabitRepositoryImpl @Inject constructor(
    private val dao: HabitDao
) : HabitRepository {
    override suspend fun findById(id: HabitId): Habit? =
        withContext(Dispatchers.IO) { dao.findById(id.value)?.toDomain() }
}
```

### Flow

- Repository methods that emit lists use `Flow<List<T>>`
- ViewModels convert `Flow` to `StateFlow` using `stateIn`

```kotlin
val habits: StateFlow<HabitListUiState> = habitRepository
    .observeAll()
    .map { habits -> HabitListUiState.Success(habits.map { it.toUiModel() }) }
    .catch { emit(HabitListUiState.Error(it.message ?: "Unknown error")) }
    .stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = HabitListUiState.Loading
    )
```

## Jetpack Compose conventions

### Composable naming

- Screens: `HabitDashboardScreen`, `HabitDetailScreen` (noun + "Screen")
- Components: `HabitCard`, `StreakBadge`, `CarbonSummaryRow` (noun, no suffix)
- Previews: same name with `Preview` suffix

### Composable structure

```kotlin
@Composable
fun HabitCard(
    habit: HabitUiModel,
    onCompleteClick: () -> Unit,
    modifier: Modifier = Modifier   // always last, always has a default
) {
    Card(
        modifier = modifier.semantics {
            contentDescription = "Habit: ${habit.name}. " +
                "Category: ${habit.category}. " +
                "Streak: ${habit.streakLabel}. " +
                if (habit.isCompletedToday) "Completed today." else "Not completed today."
        }
    ) {
        // ...
    }
}

@Preview(showBackground = true)
@Composable
private fun HabitCardPreview() {
    EcoTrackTheme {
        HabitCard(
            habit = HabitUiModel.preview(),
            onCompleteClick = {}
        )
    }
}
```

### State hoisting

Always hoist state up. Composables receive values and callbacks, never read from ViewModel directly.

```kotlin
// Correct — state hoisted to screen level
@Composable
fun HabitDashboardScreen(viewModel: HabitDashboardViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    HabitDashboardContent(
        uiState = uiState,
        onHabitComplete = viewModel::onHabitComplete
    )
}

@Composable
fun HabitDashboardContent(
    uiState: HabitListUiState,
    onHabitComplete: (HabitId) -> Unit
) { /* pure rendering */ }
```

### Avoiding recomposition

```kotlin
// Use remember for expensive calculations
val sortedHabits = remember(habits) {
    habits.sortedByDescending { it.currentStreak }
}

// Use derivedStateOf when derived from other state
val completionCount by remember {
    derivedStateOf { habits.count { it.isCompletedToday } }
}

// Use key() in LazyColumn to help Compose identify items
LazyColumn {
    items(habits, key = { it.id.value }) { habit ->
        HabitCard(habit = habit, onCompleteClick = { onHabitComplete(habit.id) })
    }
}
```

## Testing conventions

### Unit test structure (Arrange / Act / Assert)

```kotlin
@Test
fun `streak is zero when no completions`() {
    // Arrange
    val habit = buildHabit(completions = emptyList())

    // Act
    val streak = habit.currentStreak()

    // Assert
    assertEquals(0, streak)
}
```

### ViewModel testing with Turbine

```kotlin
@Test
fun `completing habit emits updated state`() = runTest {
    val viewModel = HabitDashboardViewModel(fakeUseCase)

    viewModel.uiState.test {
        val initial = awaitItem()
        assertTrue(initial is HabitListUiState.Loading)

        viewModel.onHabitComplete(habitId)

        val updated = awaitItem()
        assertTrue(updated is HabitListUiState.Success)
        assertTrue((updated as HabitListUiState.Success).habits.first().isCompletedToday)
    }
}
```

### Fake vs Mock

- Domain layer: prefer **fake** implementations (in-memory `FakeHabitRepository`)
- Presentation layer: prefer **mock** with Mockito-Kotlin for collaborators
- Never mock domain entities — use real instances via builder functions

```kotlin
// Fake — for domain use case tests
class FakeHabitRepository : HabitRepository {
    private val habits = mutableMapOf<HabitId, Habit>()
    override suspend fun findById(id: HabitId) = habits[id]
    override suspend fun save(habit: Habit) { habits[habit.id] = habit }
    override fun observeAll() = flowOf(habits.values.toList())
}
```

## Room (local storage) conventions

```kotlin
@Entity(tableName = "habits")
data class HabitEntity(
    @PrimaryKey val id: String,
    val name: String,
    val category: String,
    val frequencyPerWeek: Int,
    val carbonSavedGrams: Int,
    val isArchived: Boolean,
    val createdAt: Long          // epoch millis
)

// Always define mapper extension functions — never expose Entity to domain
fun HabitEntity.toDomain(): Habit = Habit(
    id = HabitId(id),
    name = name,
    // ...
)

fun Habit.toEntity(): HabitEntity = HabitEntity(
    id = id.value,
    // ...
)
```

## Hilt dependency injection

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides
    @Singleton
    fun provideHabitRepository(dao: HabitDao): HabitRepository =
        HabitRepositoryImpl(dao)
}
```

- Use `@Singleton` for repositories, `@ViewModelScoped` for use cases
- Bind interfaces, not implementations — the ViewModel depends on `HabitRepository`, not `HabitRepositoryImpl`

## Accessibility checklist (auto-applied by Copilot)

When generating any Composable with images, icons, or interactive elements:

1. Add `contentDescription` to every `Icon` and `Image`
2. Add `semantics { contentDescription = "..." }` to tappable `Card` or `Box`
3. Use `stateDescription` for toggling elements (completed / not completed)
4. Ensure touch target >= 48dp with `Modifier.minimumInteractiveComponentSize()`
5. Use `mergeDescendants = true` in semantics for complex card layouts
6. Test with `hasContentDescription()` in Compose tests, not raw text

## Eco-conception checklist (auto-applied by Copilot)

When generating any data-fetching or background code:

1. Use `WorkManager` for deferred/periodic work — never `AlarmManager` for periodic tasks
2. Specify `NetworkType.CONNECTED` constraint for sync workers
3. Wrap network calls in `Result.runCatching { }` — never let exceptions propagate silently
4. Cache aggressively in Room — avoid network calls if local data is fresh (< 15 minutes)
5. Use `Paging 3` for lists > 50 items
6. Prefer SVG/vector assets over PNG bitmaps

## Logging conventions

Prefer [Timber](https://github.com/JakeWharton/timber) over `android.util.Log` for all logging.
Timber integrates with crash reporters, respects release/debug builds, and removes boilerplate tags.

```kotlin
// Correct — Timber
Timber.d("Habit saved: %s", habit.id.value)
Timber.e(exception, "Failed to complete habit")

// Avoid — android.util.Log
Log.d(TAG, "Habit saved: ${habit.id}") // no crash integration, verbose tag setup
```

**PII rule — applies to all logging frameworks (Log, Timber, Logcat, etc.) :**
- NEVER log user-generated content: habit names, notes, personal descriptions
- NEVER log user identifiers in plain text (name, email, phone)
- Habit IDs and system events are safe to log
- Bad: `Timber.d("Completing habit: ${habit.title}")`
- Good: `Timber.d("Completing habit ID: %s", habitId.value)`

Domain layer: no logging of any kind. Logging belongs in use cases and above.
