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
  Section,
  Stack,
} from 'tgui-core/components';
import { Window } from 'tgui/layouts';

import { LoadingScreen } from './common/LoadingScreen';

type LobbyData = {
  character_name: string;
  round_start: BooleanLike;
  readied: BooleanLike;
  preference_issues: string[];
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

export const LobbyMenu = () => {
  const { data } = useBackend<LobbyData>();

  const { preference_issues } = data;

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
      <audio src={resolveAsset('load.mp3')} ref={onLoadPlayer} />
      <Window.Content
        className={classes([
          'LobbyScreen',
          !themeDisabled && 'crtTheme',
          !filterDisabled && 'filterEnabled',
          disableAnimations && 'noAnimation',
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
          <Box
            height="100%"
            width="100%"
            style={{
              backgroundImage: `url(${resolveAsset('lobby_art.png')})`,
            }}
            className="bgLoad bgBackground"
          />
          <Box height="100%" width="100%" position="absolute" className="crt" />
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
          <Box
            position="absolute"
            left={3}
            top={-2}
            height="100%"
            className="messageHolder"
          >
            <Stack vertical justify="flex-end" fill>
              {preference_issues.map((issue, index) => (
                <Section key={index} className="sectionLoad">
                  <Box>{issue}</Box>
                </Section>
              ))}
            </Stack>
          </Box>
        </LobbyContext.Provider>
      </Window.Content>
    </Window>
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

  const { character_name, round_start, readied } = data;

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

        <TimedDivider />

        <LobbyButton
          index={5}
          icon="eye"
          onClick={() => act('observe')}
        >
          Observe
        </LobbyButton>

        {round_start ? (
          <Stack.Item>
            <LobbyButton
              index={6}
              selected={!!readied}
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
                  index={6}
                  onClick={() => act('late_join')}
                  icon="users"
                >
                  Join Game
                </LobbyButton>
              </Stack.Item>
              <Stack.Item>
                <LobbyButton
                  icon="list"
                  tooltip="View Crew Manifest"
                  index={6 + SMALL_BUTTON_DELAY}
                  onClick={() => act('manifest')}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        )}
      </Stack>
    </Section>
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
};

const LobbyButton = (props: LobbyButtonProps) => {
  const { children, index, className, ...rest } = props;

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
