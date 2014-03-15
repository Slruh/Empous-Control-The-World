typedef enum {
    REINFORCEMENTS,
    ATTACK,
    MOVE_VICTORY,
    FORTIFY,
    TURN_OVER,
    TURN_OVER_FAILED_SEND,
    GAME_OVER,
    FIRST_TIME,
} GamePhase;

typedef enum{
    WIN,
    LOSE,
    DRAW
} AttackResult;

typedef enum{
    WILD,
    INFANTY,
    HORSE,
    CANNON
}PlayingCard;