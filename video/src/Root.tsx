import React from 'react';
import { Composition } from 'remotion';
import { WalletMeltPromo } from './WalletMeltPromo';
import './styles.css';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="WalletMeltPromo"
        component={WalletMeltPromo}
        durationInFrames={300}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{}}
      />
    </>
  );
};
