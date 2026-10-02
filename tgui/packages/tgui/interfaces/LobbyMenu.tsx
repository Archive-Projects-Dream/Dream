import { type BooleanLike, classes } from 'tgui-core/react';
import { storage } from 'common/storage';
import {
  type ComponentProps,
  createContext,
  type PropsWithChildren,
  type ReactNode,
  useContext,
  useEffect,
  useRef,
  useState,
} from 'react';
import { resolveAsset } from 'tgui/assets';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button as NativeButton,
  Modal,
  Section,
  Stack,
} from 'tgui-core/components';
import { Window } from 'tgui/layouts';

import { LoadingScreen } from './common/LoadingScreen';

type LobbyData = {
  character_name: string;

  round_start: BooleanLike;
  round_starting: BooleanLike;
  readied: BooleanLike;

  preference_issues: string[];

  server_name: string;
  map_name: string;
  player_count: number;
  ready_count: number;
  admin_count: number;
  admin_ready_count: number;
  shift_time: string | null;

  has_new_poll: BooleanLike;
  can_poll: BooleanLike;

  preview_urls: Record<string, string> | null;
  transparent: BooleanLike;

  lobby_author: string | null;
};

type LobbyContextType = {
  animationsDisable: boolean;
  themeDisable: boolean;
  setModal?: (_: ReactNode | false) => void;
};

const LobbyContext = createContext<LobbyContextType>({
  animationsDisable: false,
  themeDisable: false,
});

const PREVIEW_DIRS = ['south', 'east', 'north', 'west'] as const;

export const LobbyMenu = () => {
  const { data } = useBackend<LobbyData>();

  const { preference_issues, lobby_author, transparent } = data;

  const onLoadPlayer = useRef<HTMLAudioElement>(null);

  const [modal, setModal] = useState<ReactNode | false>(false);

  const [disableAnimations, setDisableAnimations] = useState(false);
  const [filterDisabled, setFilterDisabled] = useState(false);
  const [themeDisabled, setThemeDisabled] = useState<boolean | undefined>();

  useEffect(() => {
    storage
      .get('lobby-filter-disabled')
      .then((val) => setFilterDisabled(!!val));

    storage.get('lobby-theme-disabled').then((val) => setThemeDisabled(!!val));

    setTimeout(() => {
      onLoadPlayer.current?.play();
    }, 250);

    setTimeout(() => {
      setDisableAnimations(true);
    }, 10000);
  }, []);

  const [hidden, setHidden] = useState<boolean>(false);

  const [fadingOut, setFadingOut] = useState<boolean>(false);

  useEffect(() => {
    // Smoothly fade the lobby out when the player enters the game.
    // Sent by /datum/lobby_menu/proc/send_fade_out() right before the
    // window is torn down.
    Byond.subscribeTo('lobbyFadeOut', () => setFadingOut(true));
  }, []);

  if (themeDisabled === undefined) {
    return (
      <Window>
        <Window.Content fitted>
          <LoadingScreen />
        </Window.Content>
      </Window>
    );
  }

  const themeToUse = themeDisabled ? 'weyland_yutani' : 'crtlobby';

  return (
    <Window theme={themeToUse}>
      <style
        dangerouslySetInnerHTML={{
          __html:
            '.Window .TitleBar { display: none !important; }' +
            '.Window .Window__rest { top: 0 !important; bottom: 0 !important; left: 0 !important; right: 0 !important; }' +
            (transparent
              ? ' .Window, .Window__rest, .Window__content { background: transparent !important; box-shadow: none !important; }'
              : ''),
        }}
      />
      <audio src={resolveAsset('load.mp3')} ref={onLoadPlayer} />
      <Window.Content
        className={classes([
          'LobbyScreen',
          !themeDisabled && 'crtTheme',
          !filterDisabled && 'filterEnabled',
          disableAnimations && 'noAnimation',
          fadingOut && 'lobbyFadeOut',
          !!transparent && 'LobbyScreen--transparent',
        ])}
        fitted
      >
        <LobbyContext.Provider
          value={{
            animationsDisable: disableAnimations,
            themeDisable: themeDisabled,
            setModal: setModal,
          }}
        >
          {!!modal && <Modal>{modal}</Modal>}
          {!transparent && (
            <Box
              height="100%"
              width="100%"
              style={{
                backgroundImage: `url(${resolveAsset('lobby_art.png')})`,
              }}
              className="bgLoad bgBackground"
            />
          )}
          {!transparent && (
            <Box height="100%" width="100%" position="absolute" className="crt" />
          )}
          <Box position="absolute" top="10px" right="10px">
            <Button
              icon="cog"
              onClick={() => {
                setModal(
                  <Box className="styledText">
                    <Section
                      p={5}
                      title="Lobby Settings"
                      buttons={
                        <Button icon="xmark" onClick={() => setModal(false)} />
                      }
                      className="styledText"
                    >
                      <Stack>
                        <Stack.Item>
                          <Button
                            icon="tv"
                            onClick={() => {
                              storage.set(
                                'lobby-filter-disabled',
                                !filterDisabled,
                              );
                              setFilterDisabled(!filterDisabled);
                              setModal(false);
                            }}
                            tooltip="Removes the CRT filter background"
                          >
                            {`${filterDisabled ? 'Enable' : 'Disable'} Cinema Mode`}
                          </Button>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            icon="bolt"
                            onClick={() => {
                              storage.set(
                                'lobby-theme-disabled',
                                !themeDisabled,
                              );
                              setThemeDisabled(!themeDisabled);
                              setModal(false);
                            }}
                            tooltip="Totally removes the CRT theme, including the filter"
                          >
                            {`${themeDisabled ? 'Enable' : 'Disable'} CRT Theme`}
                          </Button>
                        </Stack.Item>
                      </Stack>
                    </Section>
                  </Box>,
                );
              }}
            />
          </Box>
          {hidden && (
            <Box position="absolute" top="10px" left="10px">
              <Button icon={'check'} onClick={() => setHidden(false)} />
            </Box>
          )}
          <Stack vertical height="100%" justify="space-around" align="center">
            <Stack.Item>
              <LobbyButtons
                setModal={setModal}
                hidden={hidden}
                setHidden={setHidden}
              />
            </Stack.Item>
          </Stack>
          {!hidden && (
            <Box className="lobby__left">
              <CharacterPreview />
              <StatsPanel />
            </Box>
          )}
          <Box
            position="absolute"
            left={3}
            top={-2}
            height="100%"
            className="messageHolder"
          >
            <Stack vertical justify="flex-end" fill>
              {preference_issues.map((issue, index) => (
                <Section key={index} className="sectionLoad issueSection">
                  <Box className="issueText">{issue}</Box>
                </Section>
              ))}
            </Stack>
          </Box>
          <Box className="bgLoad authorAttrib styledText">
            {lobby_author ? `Art by ${lobby_author}` : ''}
          </Box>
        </LobbyContext.Provider>
      </Window.Content>
    </Window>
  );
};

const ModalConfirm = (props: PropsWithChildren) => {
  const { children } = props;

  const context = useContext(LobbyContext);

  const { setModal } = context;

  return (
    <Section
      buttons={<Button mb={5} onClick={() => setModal!(false)} icon={'x'} />}
      p={3}
      title={'Confirm'}
    >
      {children}
    </Section>
  );
};

const SMALL_BUTTON_DELAY = 3;

const LobbyButtons = (props: {
  readonly setModal: (_) => void;
  readonly hidden: boolean;
  readonly setHidden: (_: boolean) => void;
}) => {
  const { act, data } = useBackend<LobbyData>();

  const { setModal, hidden, setHidden } = props;

  const {
    character_name,
    round_start,
    round_starting,
    readied,
    has_new_poll,
    can_poll,
  } = data;

  return (
    <Section
      p={3}
      className="sectionLoad"
      style={{
        opacity: hidden ? '0' : '1',
      }}
    >
      <Stack vertical>
        <Stack.Item>
          <Stack>
            <Stack.Item minWidth="200px">
              <Stack vertical>
                <Stack.Item>
                  <Stack justify="center">
                    <Stack.Item>
                      <Box className="typeEffect styledText">Welcome,</Box>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item>
                  <Stack justify="center">
                    <Stack.Item>
                      <Box
                        className="typeEffect styledText"
                        style={{
                          animationDelay: '1.4s',
                        }}
                      >
                        {character_name}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <TimedDivider />

        <LobbyButton
          index={1}
          onClick={() => act('preferences')}
          icon="file-lines"
        >
          Setup Character
        </LobbyButton>

        <LobbyButton
          index={2}
          icon="gear"
          onClick={() => act('game_preferences')}
        >
          Game Preferences
        </LobbyButton>

        <LobbyButton index={3} icon="check-to-slot" onClick={() => act('manifest')}>
          Crew Manifest
        </LobbyButton>

        <LobbyButton index={4} onClick={() => act('changelog')} icon="list-ul">
          Changelog
        </LobbyButton>

        {!!can_poll && (
          <LobbyButton
            index={5}
            icon="clipboard-list"
            onClick={() => act('polls')}
            badge={has_new_poll ? 'New poll!' : null}
          >
            Polls
          </LobbyButton>
        )}

        <TimedDivider />

        <LobbyButton
          index={6}
          icon="eye"
          disabled={!!round_starting}
          onClick={() => {
            setModal(
              <ModalConfirm>
                <Box>
                  <Stack vertical>
                    <Stack.Item>Are you sure you wish to observe?</Stack.Item>
                    <Stack.Item>
                      When you observe, you will not be able to join the
                      round as your character.
                    </Stack.Item>
                  </Stack>
                  <Stack justify="center">
                    <Stack.Item>
                      <Button onClick={() => act('observe', { confirmed: 1 })}>
                        Confirm
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Box>
              </ModalConfirm>,
            );
          }}
        >
          Observe
        </LobbyButton>

        {round_start ? (
          <Stack.Item>
            <LobbyButton
              index={7}
              selected={!!readied}
              disabled={!!round_starting}
              onClick={() => act(readied ? 'unready' : 'ready')}
              icon={readied ? 'check' : 'xmark'}
            >
              {readied ? 'Unready' : 'Ready'}
            </LobbyButton>
          </Stack.Item>
        ) : (
          <Stack.Item>
            <Stack>
              <Stack.Item grow>
                <LobbyButton
                  index={7}
                  onClick={() => act('late_join')}
                  icon="users"
                  disabled={!!round_starting}
                >
                  Join Game
                </LobbyButton>
              </Stack.Item>
              <Stack.Item>
                <LobbyButton
                  icon="list"
                  tooltip="View Crew Manifest"
                  index={7 + SMALL_BUTTON_DELAY}
                  onClick={() => act('manifest')}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        )}

        <Stack.Item>
          <Button
            fluid
            className="hideButton"
            icon="eye-slash"
            onClick={() => setHidden(true)}
          >
            <span className="styledText">{'Hide Menu'}</span>
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

/** Character preview with client-side direction cycling. */
const CharacterPreview = () => {
  const { act, data } = useBackend<LobbyData>();

  const { preview_urls } = data;

  const [dirIndex, setDirIndex] = useState(0);

  const urls = preview_urls;

  if (!urls) {
    return null;
  }

  const dir = PREVIEW_DIRS[dirIndex] ?? Object.keys(urls)[0];
  const url = urls[dir] ?? Object.values(urls)[0];

  return (
    <div className="lobby__preview">
      <div className="lobby__panel-title">{'Character'}</div>
      <div className="lobby__preview-body">
        {url && <img className="lobby__preview-img" src={url} alt="" />}
      </div>
      <Stack className="lobby__preview-buttons">
        <Stack.Item grow>
          <Button
            fluid
            compact
            icon="rotate"
            onClick={() => {
              setDirIndex((dirIndex + 1) % PREVIEW_DIRS.length);
            }}
          >
            {'Rotate'}
          </Button>
        </Stack.Item>
        <Stack.Item grow>
          <Button
            fluid
            compact
            icon="arrows-rotate"
            onClick={() => act('refresh_preview')}
          >
            {'Refresh'}
          </Button>
        </Stack.Item>
      </Stack>
    </div>
  );
};

const StatsRow = ({ label, value }: { label: string; value: string | null }) => {
  return (
    <div className="lobby__stats-row">
      <span className="lobby__stats-label">{label}</span>
      <span className="lobby__stats-value">{value || '—'}</span>
    </div>
  );
};

/** Round/server statistics panel. */
const StatsPanel = () => {
  const { data } = useBackend<LobbyData>();

  const {
    server_name,
    map_name,
    round_start,
    round_starting,
    shift_time,
    player_count,
    ready_count,
    admin_count,
    admin_ready_count,
  } = data;

  const status = round_start
    ? round_starting
      ? 'Starting soon'
      : 'Pre-game'
    : 'Round in progress';

  return (
    <div className="lobby__stats">
      <div className="lobby__panel-title">{'Server'}</div>
      <StatsRow label={'Server'} value={server_name} />
      <StatsRow label={'Map'} value={map_name} />
      <StatsRow label={'Status'} value={status} />
      {round_start ? (
        <StatsRow label={'Players ready'} value={`${ready_count} / ${player_count}`} />
      ) : (
        <StatsRow label={'Shift time'} value={shift_time} />
      )}
      <StatsRow label={'Players'} value={String(player_count)} />
      <StatsRow label={'Admins'} value={`${admin_ready_count} / ${admin_count}`} />
    </div>
  );
};

const TimedDivider = () => {
  const ref = useRef<HTMLDivElement>(null);

  const context = useContext(LobbyContext);

  const { themeDisable } = context;

  useEffect(() => {
    if (!themeDisable) {
      setTimeout(() => {
        if (ref.current) {
          ref.current.style.display = 'block';
        }
      }, 1500);
    }
  }, [themeDisable]);

  return (
    <Stack.Item>
      <div
        style={{
          borderStyle: 'solid',
          borderWidth: '1px',
          display: themeDisable ? 'block' : 'none',
        }}
        className="dividerEffect"
        ref={ref}
      />
    </Stack.Item>
  );
};

type LobbyButtonProps = ComponentProps<typeof Box> & {
  readonly index: number;
  readonly selected?: boolean;
  readonly disabled?: boolean;
  readonly icon?: string;
  readonly tooltip?: string;
  readonly badge?: string | null;
};

const LobbyButton = (props: LobbyButtonProps) => {
  const { children, index, className, badge, ...rest } = props;

  const context = useContext<LobbyContextType>(LobbyContext);

  return (
    <Stack.Item
      className="buttonEffect"
      style={{
        animationDelay: context.animationsDisable
          ? '0s'
          : `${1.5 + index * 0.2}s`,
      }}
    >
      <Button fluid className={'distinctButton ' + className} {...rest}>
        <StyledText>{children}</StyledText>
        {!!badge && <span className="badgeNotification">{badge}</span>}
      </Button>
    </Stack.Item>
  );
};

const StyledText = (props: PropsWithChildren) => {
  const { children } = props;

  return (
    <Box inline className="styledText">
      {children}
    </Box>
  );
};

const Button = (props: ComponentProps<typeof NativeButton>) => {
  const { act } = useBackend();

  return (
    <Box onClick={() => act('keyboard')}>
      <NativeButton {...props} />
    </Box>
  );
};
